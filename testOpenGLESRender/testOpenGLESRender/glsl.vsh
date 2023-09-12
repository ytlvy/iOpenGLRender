attribute vec4 i_position;
attribute vec2 i_textureCoord;
varying vec2 TextureCoordsVarying;

void main (void) {
    gl_Position = i_position;
    TextureCoordsVarying = i_textureCoord;
}
