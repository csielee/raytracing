#ifndef PTHREAD
#define PTHREAD 1

typedef struct __PTHREAD_PARAMETER {
    uint8_t *pixels;
    color background_color;
    rectangular_node rectangulars;
    sphere_node spheres;
    light_node lights;
    const viewpoint *view;
    int width_start;
    int width;
    int height_start;
    int height;
} pthread_para;

void raytracing_pthread(void *a)
{
    pthread_para *para = a;
    point u, v, w, d;
    color object_color = { 0.0, 0.0, 0.0 };

    calculateBasisVectors(u, v, w, view);

    idx_stack stk;
    int factor = sqrt(SAMPLES);
    for (int j = para->height_start; j < para->height; j += THREAD_NUMBER) {
        for (int i = para->width_start; i < para->width; i += THREAD_NUMBER) {
            double r = 0, g = 0, b = 0;
            for (int s = 0; s < SAMPLES; s++) {
                idx_stack_init(&stk);
                rayConstruction(d, u, v, w, i*factor+s/factor,j*factor+s%factor,para->view,para->width*factor,para->height*factor);
                if (ray_color(para->view->vrp, 0.0, d, &stk, para->rectangulars, para->spheres,para->lights,object_color,MAX_REFLECTION_BOUNCES)) {
                    r += object_color[0];
                    g += object_color[1];
                    b += object_color[2];
                } else {
                    r += para->background_color[0];
                    g += para->background_color[1];
                    b += para->background_color[2];
                }
                para->pixels[((i + (j * para->width)) * 3) + 0] = r * 255 / SAMPLES;
                para->pixels[((i + (j * para->width)) * 3) + 1] = g * 255 / SAMPLES;
                para->pixels[((i + (j * para->width)) * 3) + 2] = b * 255 / SAMPLES;
            }
        }
    }
    pthread_exit(1);
}

#endif
