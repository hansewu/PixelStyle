#ifndef LAGRANGEHPP
#define LAGRANGEHPP

#include <vector>


class Lagrange{
private:
    std::vector<float> x;
    std::vector<float> fx;

public:
    void insertSamples(std::vector<float> X, std::vector<float> FX);
    float interpolate(float value);
    Lagrange(std::vector<float> X, std::vector<float> FX);
    //~Lagrange();
};




#endif
