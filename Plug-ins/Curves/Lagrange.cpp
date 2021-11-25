#include "Lagrange.hpp"

Lagrange::Lagrange(std::vector<float> X, std::vector<float> FX){
    this->fx = FX;
    this->x = X;
}

void Lagrange::insertSamples(std::vector<float> X, std::vector<float> FX){
    this->fx = FX;
    this->x = X;
}


float Lagrange::interpolate(float value){
    if(fx.size() != x.size()  || (x.size() == 0)){
        return 0.0;
    }

    float result = 0;

    float up, down;
    for(int i = 0; i < x.size(); i++){
        up = down = 1;
        for(int j = 0; j < x.size(); j++){
            if(j != i){
                up *= (value - x[j]);
                down *= (x[i] - x[j]);
            }
        }
        result += ((up/down)*fx[i]);
    }
    return result;
}
