#include "rive/rive_types.hpp"

#include "rive/renderer/rive_render_image.hpp"
#include "rive/renderer/gl/render_context_gl_impl.hpp"
#include "rive/renderer/rive_renderer.hpp"
#include "rive/renderer/gl/render_target_gl.hpp"

#include <emscripten.h>
#include <emscripten/bind.h>
#include <emscripten/val.h>
#include <emscripten/html5.h>
using namespace emscripten;

#include <stdint.h>
#include <stdio.h>
#include <string>
#include <map>
#include <set>
#include <vector>

using namespace rive;
using namespace rive::gpu;

class WebGL2Renderer;
class WebGL2RenderImage;
class WebGL2RenderBuffer;

using PLSResourceID = uint64_t;
using WasmPtr = uint32_t;

static std::atomic<PLSResourceID> s_nextWebGL2BufferID;

#define EXPORT extern "C" EMSCRIPTEN_KEEPALIVE

// Singleton RiveRenderFactory implementation for WebGL 2.
// All objects are context free and keyed to actual resources the the specific
// GL contexts.
class WebGL2Factory : public RiveRenderFactory
{
public:
    static WebGL2Factory* Instance()
    {
        static WebGL2Factory s_webGLFactory;
        return &s_webGLFactory;
    }

    // Register GL contexts for resource deletion notifications.
    void registerContext(WebGL2Renderer* renderer)
    {
        m_renderers.insert(renderer);
    }
    void unregisterContext(WebGL2Renderer* renderer)
    {
        m_renderers.erase(renderer);
    }

    // Hooks for WebGL 2 objects to notify all contexts when they get deleted.
    void onWebGL2BufferDeleted(WebGL2RenderBuffer*);

    rcp<RenderImage> decodeImage(Span<const uint8_t> encodedBytes) override;
    rcp<RenderBuffer> makeRenderBuffer(RenderBufferType,
                                       RenderBufferFlags,
                                       size_t sizeInBytes) override;

private:
    WebGL2Factory() = default;

    std::set<WebGL2Renderer*> m_renderers;
};

EM_JS(void,
      decode_image,
      (uintptr_t renderImage, uintptr_t imgDataPtr, int imgDataLength),
      {
          var images = Module["images"];
          if (!images)
          {
              images = new Map();
              Module["images"] = images;
          }

          var image = new Image();
          images.set(renderImage, image);
          // Copy heap as it's a SharedBufferArray which cannot be used for
          // Blob.
          var sourceView =
              Module["HEAP8"].subarray(imgDataPtr, imgDataPtr + imgDataLength);
          var buffer = new Uint8Array(imgDataLength);
          buffer.set(sourceView);
          image.src = URL.createObjectURL(new Blob([buffer], {
              type:
                  "image/png"
          }));
          image.onload = function()
          {
              Module["_setWebImage"](renderImage, image.width, image.height);
          };
      });

// RAII utility to set and restore the current GL context.
class ScopedGLContextMakeCurrent
{
public:
    ScopedGLContextMakeCurrent(EMSCRIPTEN_WEBGL_CONTEXT_HANDLE contextGL) :
        m_contextGL(contextGL),
        m_previousContext(emscripten_webgl_get_current_context())
    {
        if (m_contextGL != m_previousContext)
        {
            emscripten_webgl_make_context_current(m_contextGL);
        }
    }

    ~ScopedGLContextMakeCurrent()
    {
        if (m_contextGL != m_previousContext)
        {
            emscripten_webgl_make_context_current(m_previousContext);
        }
    }

private:
    const EMSCRIPTEN_WEBGL_CONTEXT_HANDLE m_contextGL;
    const EMSCRIPTEN_WEBGL_CONTEXT_HANDLE m_previousContext;
};

EM_JS(void,
      upload_image,
      (EMSCRIPTEN_WEBGL_CONTEXT_HANDLE gl, uintptr_t renderImage),
      {
          var images = Module["images"];
          if (!images)
          {
              return;
          }

          var image = images.get(renderImage);
          if (!image)
          {
              return;
          }
          gl = GL.getContext(gl).GLctx;
          gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, true);
          gl.texImage2D(gl.TEXTURE_2D,
                        0,
                        gl.RGBA,
                        gl.RGBA,
                        gl.UNSIGNED_BYTE,
                        image);
          gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, false);
      });

EM_JS(void, delete_image, (uintptr_t renderImage), {
    var images = Module["images"];
    if (!images)
    {
        return;
    }

    var image = images.get(renderImage);
    if (!image)
    {
        return;
    }
    images.delete(renderImage);
});

// High-level, context agnostic RenderImage for the WebGL2 system. Wraps a blob
// of encoded image data, which is then decoded and uploaded to a texture on
// each separate context.
class WebGL2RenderImage
    : public LITE_RTTI_OVERRIDE(RenderImage, WebGL2RenderImage)
{
public:
    WebGL2RenderImage(Span<const uint8_t> encodedBytes)
    {
        m_Width = 0;
        m_Height = 0;

        ref();
        decode_image(reinterpret_cast<uintptr_t>(this),
                     // decode_image copies these so we don't need to allocate
                     // storage for them
                     reinterpret_cast<uintptr_t>(encodedBytes.data()),
                     encodedBytes.size());
    }

    ~WebGL2RenderImage()
    {
        ScopedGLContextMakeCurrent makeCurrent(m_contextGL);
        delete_image(reinterpret_cast<uintptr_t>(this));
        m_renderImage.reset();
    }

    void setWebImage(int width, int height)
    {
        m_Width = width;
        m_Height = height;
        m_readyToUpload = true;
        decodedAsync();
    }

private:
    bool m_readyToUpload = false;
    EMSCRIPTEN_WEBGL_CONTEXT_HANDLE m_contextGL = 0;
    rcp<RiveRenderImage> m_renderImage;

public:
    RenderImage* prep(WebGL2Renderer* webglRenderer,
                      const EMSCRIPTEN_WEBGL_CONTEXT_HANDLE context);
};

EXPORT void setWebImage(WebGL2RenderImage* renderImage, int width, int height)
{
    renderImage->setWebImage(width, height);
    renderImage->unref();
}

// Shared object that holds the contents of a WebGL2Buffer. PLS buffers are
// synchronized to these contents on every draw.
class WebGL2BufferData : public RefCnt<WebGL2BufferData>
{
public:
    WebGL2BufferData(size_t sizeInBytes) : m_data(new uint8_t[sizeInBytes]) {}

    const uint8_t* contents() const { return m_data.get(); }

    uint8_t* writableAddress()
    {
        ++m_mutationID;
        return m_data.get();
    }

    // Used to know when a PLS buffer is out of sync.
    PLSResourceID mutationID() const { return m_mutationID; }

private:
    std::unique_ptr<uint8_t[]> m_data;
    PLSResourceID m_mutationID =
        1; // So a 0-initialized PLS buffer will be out of sync.
};

// High-level, context agnostic RenderBuffer for the WebGL2 system. Wraps the
// buffer contents in a shared CPU-side WebGL2BufferData object, against which
// low-level PLS buffers are synchronized.
class WebGL2RenderBuffer
    : public LITE_RTTI_OVERRIDE(RenderBuffer, WebGL2RenderBuffer)
{
public:
    WebGL2RenderBuffer(RenderBufferType type,
                       RenderBufferFlags flags,
                       size_t sizeInBytes) :
        lite_rtti_override(type, flags, sizeInBytes),
        m_bufferData(make_rcp<WebGL2BufferData>(sizeInBytes))
    {}

    ~WebGL2RenderBuffer()
    {
        WebGL2Factory::Instance()->onWebGL2BufferDeleted(this);
    }

    PLSResourceID uniqueID() const { return m_uniqueID; }
    rcp<WebGL2BufferData> bufferData() { return m_bufferData; }

    void* onMap() override { return m_bufferData->writableAddress(); }
    void onUnmap() override {}

private:
    const PLSResourceID m_uniqueID = ++s_nextWebGL2BufferID;
    rcp<WebGL2BufferData> m_bufferData;
};

// Wraps a PLS renderBuffer and keeps its contents synchronized to the given
// WebGL2BufferData.
class PLSSynchronizedBuffer
{
public:
    PLSSynchronizedBuffer(WebGL2Renderer*, WebGL2RenderBuffer*);

    ~PLSSynchronizedBuffer()
    {
        ScopedGLContextMakeCurrent makeCurrent(m_contextGL);
        m_renderBuffer.reset();
    }

    rcp<RenderBuffer> get()
    {
        if (m_mutationID != m_webglBufferData->mutationID())
        {
            ScopedGLContextMakeCurrent makeCurrent(m_contextGL);
            void* contents = m_renderBuffer->map();
            memcpy(contents,
                   m_webglBufferData->contents(),
                   m_renderBuffer->sizeInBytes());
            m_mutationID = m_webglBufferData->mutationID();
            m_renderBuffer->unmap();
        }
        return m_renderBuffer;
    }

private:
    const EMSCRIPTEN_WEBGL_CONTEXT_HANDLE m_contextGL;
    const rcp<WebGL2BufferData> m_webglBufferData;
    rcp<RenderBuffer> m_renderBuffer;
    PLSResourceID m_mutationID =
        0; // Tells when we are out of sync with the WebGL2BufferData.
};

// Wraps a tightly coupled RiveRenderer and RenderContext, which are tied to a
// specific WebGL2 context.
class WebGL2Renderer : public RiveRenderer
{
public:
    WebGL2Renderer(std::unique_ptr<RenderContext> renderContext,
                   int width,
                   int height) :
        RiveRenderer(renderContext.get()),
        m_renderContext(std::move(renderContext))
    {
        resize(width, height);
    }

    ~WebGL2Renderer()
    {
        ScopedGLContextMakeCurrent makeCurrent(m_contextGL);
        m_plsSynchronizedBuffers.clear();
        m_renderTarget.release();
        m_renderContext.release();
    }

    EMSCRIPTEN_WEBGL_CONTEXT_HANDLE contextGL() const { return m_contextGL; }

    PLSResourceID currentFrameID() const { return m_currentFrameID; }

    RenderContextGLImpl* renderContextGL() const
    {
        return m_renderContext->static_impl_cast<RenderContextGLImpl>();
    }

    void resize(int width, int height)
    {
        ScopedGLContextMakeCurrent makeCurrent(m_contextGL);
        GLint sampleCount;
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
        glGetIntegerv(GL_SAMPLES, &sampleCount);
        m_renderTarget =
            make_rcp<FramebufferRenderTargetGL>(width, height, 0, sampleCount);
    }

    // "clear()" is our hook for the beginning of a frame.
    // TODO: Give this a better name!!
    void clear(ColorInt color)
    {
        RenderContext::FrameDescriptor frameDescriptor = {
            .renderTargetWidth = m_renderTarget->width(),
            .renderTargetHeight = m_renderTarget->height(),
            .loadAction = gpu::LoadAction::clear,
            .clearColor = color,
        };
        if (m_renderTarget->sampleCount() > 1)
        {
            // Use MSAA if we were given a canvas with 'antialias: true'.
            frameDescriptor.msaaSampleCount = m_renderTarget->sampleCount();
        }
        else if (!m_renderContext->platformFeatures().supportsRasterOrdering &&
                 !m_renderContext->platformFeatures()
                      .supportsFragmentShaderAtomics)
        {
            // Always use MSAA if we don't have
            // WEBGL_shader_pixel_local_storage.
            frameDescriptor.msaaSampleCount = 4;
        }
        m_renderContext->beginFrame(std::move(frameDescriptor));
        ++m_currentFrameID;
    }

    void saveClipRect(float l, float t, float r, float b)
    {
        save();
        rcp<RenderPath> rect(WebGL2Factory::Instance()->makeEmptyRenderPath());
        rect->moveTo(l, t);
        rect->lineTo(r, t);
        rect->lineTo(r, b);
        rect->lineTo(l, b);
        rect->close();
        clipPath(rect.get());
    }

    void restoreClipRect() { restore(); }

    void drawImage(const RenderImage* renderImage,
                   BlendMode blendMode,
                   float opacity) override
    {
        LITE_RTTI_CAST_OR_RETURN(webglRenderImage,
                                 const WebGL2RenderImage*,
                                 renderImage);
        renderImage =
            ((WebGL2RenderImage*)webglRenderImage)->prep(this, m_contextGL);
        if (renderImage != nullptr)
        {
            // The renderImage is done decoding.
            RiveRenderer::drawImage(renderImage, blendMode, opacity);
        }
    }

    void drawImageMesh(const RenderImage* renderImage,
                       rcp<RenderBuffer> vertices_f32,
                       rcp<RenderBuffer> uvCoords_f32,
                       rcp<RenderBuffer> indices_u16,
                       uint32_t vertexCount,
                       uint32_t indexCount,
                       BlendMode blendMode,
                       float opacity) override
    {
        LITE_RTTI_CAST_OR_RETURN(webglRenderImage,
                                 const WebGL2RenderImage*,
                                 renderImage);
        renderImage =
            ((WebGL2RenderImage*)webglRenderImage)->prep(this, m_contextGL);
        if (renderImage != nullptr)
        {
            // The renderImage is done decoding.
            LITE_RTTI_CAST_OR_RETURN(vertexBuffer,
                                     WebGL2RenderBuffer*,
                                     vertices_f32.get());
            LITE_RTTI_CAST_OR_RETURN(uvBuffer,
                                     WebGL2RenderBuffer*,
                                     uvCoords_f32.get());
            LITE_RTTI_CAST_OR_RETURN(indexBuffer,
                                     WebGL2RenderBuffer*,
                                     indices_u16.get());
            RiveRenderer::drawImageMesh(renderImage,
                                        refPLSBuffer(vertexBuffer),
                                        refPLSBuffer(uvBuffer),
                                        refPLSBuffer(indexBuffer),
                                        vertexCount,
                                        indexCount,
                                        blendMode,
                                        opacity);
        }
    }

    void flush()
    {
        ScopedGLContextMakeCurrent makeCurrent(m_contextGL);
        m_renderContext->flush({.renderTarget = m_renderTarget.get()});
    }

    // Delete our corresponding PLS buffer when a WebGL2RenderBuffer is deleted.
    void onWebGL2BufferDeleted(PLSResourceID webglBufferID)
    {
        m_plsSynchronizedBuffers.erase(webglBufferID);
    }

private:
    rcp<RenderBuffer> refPLSBuffer(WebGL2RenderBuffer* wglBuff)
    {
        PLSSynchronizedBuffer& synchronizedBuffer =
            m_plsSynchronizedBuffers
                .try_emplace(wglBuff->uniqueID(), this, wglBuff)
                .first->second;
        return synchronizedBuffer.get();
    }

    const EMSCRIPTEN_WEBGL_CONTEXT_HANDLE m_contextGL =
        emscripten_webgl_get_current_context();

    std::unique_ptr<RenderContext> m_renderContext;
    rcp<FramebufferRenderTargetGL> m_renderTarget;

    std::map<PLSResourceID, PLSSynchronizedBuffer> m_plsSynchronizedBuffers;

    PLSResourceID m_currentFrameID = 0;
};

RenderImage* WebGL2RenderImage::prep(
    WebGL2Renderer* webglRenderer,
    const EMSCRIPTEN_WEBGL_CONTEXT_HANDLE context)
{
    // Only return the existing render image if its from the same context,
    // otherwise we need to re-upload.
    if (context == m_contextGL && m_renderImage)
    {
        return m_renderImage.get();
    }
    if (m_readyToUpload)
    {
        ScopedGLContextMakeCurrent makeCurrent(m_contextGL = context);
        GLuint textureId = 0;
        glGenTextures(1, &textureId);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, textureId);
        webglRenderer->renderContextGL()->state()->bindBuffer(
            GL_PIXEL_UNPACK_BUFFER,
            0);
        upload_image(emscripten_webgl_get_current_context(),
                     reinterpret_cast<uintptr_t>(this));
        glGenerateMipmap(GL_TEXTURE_2D);
        glTexParameteri(GL_TEXTURE_2D,
                        GL_TEXTURE_MIN_FILTER,
                        GL_LINEAR_MIPMAP_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        m_renderImage = make_rcp<RiveRenderImage>(
            webglRenderer->renderContextGL()->adoptImageTexture(m_Width,
                                                                m_Height,
                                                                textureId));
    }
    return m_renderImage.get();
}

PLSSynchronizedBuffer::PLSSynchronizedBuffer(WebGL2Renderer* webglRenderer,
                                             WebGL2RenderBuffer* webglBuffer) :
    m_contextGL(webglRenderer->contextGL()),
    m_webglBufferData(webglBuffer->bufferData())

{
    ScopedGLContextMakeCurrent makeCurrent(m_contextGL);
    m_renderBuffer = webglRenderer->renderContextGL()->makeRenderBuffer(
        webglBuffer->type(),
        webglBuffer->flags(),
        webglBuffer->sizeInBytes());
}

rcp<RenderImage> WebGL2Factory::decodeImage(Span<const uint8_t> encodedBytes)
{
    return make_rcp<WebGL2RenderImage>(encodedBytes);
}

rcp<RenderBuffer> WebGL2Factory::makeRenderBuffer(RenderBufferType type,
                                                  RenderBufferFlags flags,
                                                  size_t sizeInBytes)
{
    return make_rcp<WebGL2RenderBuffer>(type, flags, sizeInBytes);
}

void WebGL2Factory::onWebGL2BufferDeleted(WebGL2RenderBuffer* webglRenderBuffer)
{
    for (WebGL2Renderer* renderer : m_renderers)
    {
        renderer->onWebGL2BufferDeleted(webglRenderBuffer->uniqueID());
    }
}

// JS Hooks.
Factory* riveFactory() { return WebGL2Factory::Instance(); }

WasmPtr decodeImage(WasmPtr factoryPtr, emscripten::val byteArray)
{
    std::vector<unsigned char> vector;

    const auto l = byteArray["byteLength"].as<unsigned>();
    vector.resize(l);

    emscripten::val memoryView{emscripten::typed_memory_view(l, vector.data())};
    memoryView.call<void>("set", byteArray);

    auto actualFactory = factoryPtr == 0 ? riveFactory() : (Factory*)factoryPtr;
    rcp rcpImage = actualFactory->decodeImage(vector);
    // NOTE: ref so the image does not get disposed after the scope of this
    // function.
    rcpImage->ref();
    return (WasmPtr)rcpImage.get();
}

WasmPtr makeRenderer(int width, int height)
{
    if (auto renderContext = RenderContextGLImpl::MakeContext())
    {
        auto ptr = new WebGL2Renderer(std::move(renderContext), width, height);
        return (WasmPtr)ptr;
    }
    return 0;
}

void deleteRenderer(WasmPtr rendererPtr)
{
    delete (WebGL2Renderer*)rendererPtr;
}

void clearRenderer(WasmPtr rendererPtr, uint32_t color)
{
    auto renderer = (WebGL2Renderer*)rendererPtr;
    if (renderer == nullptr)
    {
        return;
    }
    renderer->clear((ColorInt)color);
}

void flushRenderer(WasmPtr rendererPtr)
{
    auto renderer = (WebGL2Renderer*)rendererPtr;
    if (renderer == nullptr)
    {
        return;
    }
    renderer->flush();
}

void resizeRenderer(WasmPtr rendererPtr, int width, int height)
{
    auto renderer = (WebGL2Renderer*)rendererPtr;
    if (renderer == nullptr)
    {
        return;
    }
    renderer->resize(width, height);
}

void saveRenderer(WasmPtr rendererPtr)
{
    auto renderer = (WebGL2Renderer*)rendererPtr;
    if (renderer == nullptr)
    {
        return;
    }
    renderer->save();
}

void restoreRenderer(WasmPtr rendererPtr)
{
    auto renderer = (WebGL2Renderer*)rendererPtr;
    if (renderer == nullptr)
    {
        return;
    }
    renderer->restore();
}

void transformRenderer(WasmPtr rendererPtr,
                       float xx,
                       float xy,
                       float yx,
                       float yy,
                       float tx,
                       float ty)
{
    auto renderer = (WebGL2Renderer*)rendererPtr;
    if (renderer == nullptr)
    {
        return;
    }
    rive::Mat2D matrix(xx, xy, yx, yy, tx, ty);
    renderer->transform(matrix);
}

EMSCRIPTEN_BINDINGS(Rive)
{
    function("decodeImage", &decodeImage);
    function("makeRenderer", &makeRenderer);
    function("deleteRenderer", &deleteRenderer);
    function("clearRenderer", &clearRenderer);
    function("flushRenderer", &flushRenderer);
    function("resizeRenderer", &resizeRenderer);
    function("saveRenderer", &saveRenderer);
    function("restoreRenderer", &restoreRenderer);
    function("transformRenderer", &transformRenderer);
}
