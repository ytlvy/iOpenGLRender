precision mediump float;

uniform vec2 u_resolution; //画布尺寸
uniform sampler2D Texture;
varying vec2 TextureCoordsVarying;

float circleShape(vec2 position, float radius) {
    return step(radius, length(position));  //圆周以内点才有颜色
}

void main(){
    vec2 uv = gl_FragCoord.xy / u_resolution * 2.0 - 1.0; //坐标移动到中心, 病并保持比例

    vec3 color = vec3(0.);
    vec4 mask = texture2D(Texture, TextureCoordsVarying);
    color = mask.rgb;
    
    float circle_bin_color = circleShape(uv, 0.5); //确定园内为黑色, 圆外为白色
//
    color = vec3(circle_bin_color); //根据圆内外颜色不同生成vec3
    
    gl_FragColor =  vec4(color, 1.0);
}
