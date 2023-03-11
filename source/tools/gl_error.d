module tools.gl_error;

import bindbc.opengl;

GLenum getAndClearGLErrors(){
    GLenum error = glGetError();
    // Clear OpenGL errors
    while (glGetError() != GL_NO_ERROR) {
        glGetError();
    }
    return error;
}