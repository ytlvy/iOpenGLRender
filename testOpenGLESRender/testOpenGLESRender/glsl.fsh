precision mediump float;

uniform float u_time;
uniform vec2 u_resolution; //画布尺寸
uniform sampler2D u_texture;
varying vec2 TextureCoordsVarying;

#define t u_time
#define r u_resolution

float circleShape(vec2 position, float radius) {
    return step(radius, length(position));  //圆周以内点才有颜色
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    vec3 c;
    
    float l,z=t;
    for(int i=0;i<3;i++) {
        vec2 uv,p=fragCoord.xy/r;
        uv=p;
        p-=.5;
        p.x*=r.x/r.y;
        z+=.07;
        l=length(p);
        uv+=p/l*(sin(z)+1.)*abs(sin(l*9.-z-z));
        c[i]=.01/length(mod(uv,1.)-.5);
    }

    fragColor=vec4(c/l,t);
}

void main(){
    mainImage(gl_FragColor, gl_FragCoord.xy);
//    vec2 uv = gl_FragCoord.xy / u_resolution * 2.0 - 1.0; //坐标移动到中心, 病并保持比例
//
//    vec3 color = vec3(0.);
//    vec4 mask = texture2D(u_texture, TextureCoordsVarying);
//    color = mask.rgb;
//    
//    float circle_bin_color = circleShape(uv, 0.5); //确定园内为黑色, 圆外为白色
////
//    color = vec3(circle_bin_color); //根据圆内外颜色不同生成vec3
//    
//    gl_FragColor =  vec4(color, 1.0);
}
