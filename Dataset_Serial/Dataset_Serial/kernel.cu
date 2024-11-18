#include <iostream>

#include <fstream>

#include <vector>

#include <cmath>

#include <string>

#include <chrono> // Para medir o tempo de execução

#include <cuda_runtime.h>



#pragma pack(push, 1)

struct BMPHeader {

    char signature[2];

    uint32_t fileSize;

    uint32_t reserved;

    uint32_t dataOffset;

    uint32_t headerSize;

    int32_t width;

    int32_t height;

    uint16_t colorPlanes;

    uint16_t bitsPerPixel;

    uint32_t compression;

    uint32_t dataSize;

    int32_t hResolution;

    int32_t vResolution;

    uint32_t colors;

    uint32_t importantColors;

};

#pragma pack(pop)



bool saveBMP(const std::string& filename, const std::vector<uint8_t>& imageData, int width, int height) {

    std::ofstream file(filename, std::ios::binary);

    if (!file) {

        std::cerr << "Erro ao salvar o arquivo." << std::endl;

        return false;

    }



    int rowSize = ((width * 3 + 3) & ~3);

    int paddedDataSize = rowSize * height;



    BMPHeader header;

    header.signature[0] = 'B';

    header.signature[1] = 'M';

    header.fileSize = sizeof(BMPHeader) + paddedDataSize;

    header.reserved = 0;

    header.dataOffset = sizeof(BMPHeader);

    header.headerSize = 40;

    header.width = width;

    header.height = height;

    header.colorPlanes = 1;

    header.bitsPerPixel = 24;

    header.compression = 0;

    header.dataSize = paddedDataSize;

    header.hResolution = 2835;

    header.vResolution = 2835;

    header.colors = 0;

    header.importantColors = 0;



    file.write(reinterpret_cast<char*>(&header), sizeof(header));

    std::vector<uint8_t> padding(rowSize - width * 3, 0);

    for (int y = 0; y < height; ++y) {

        file.write(reinterpret_cast<const char*>(&imageData[y * width * 3]), width * 3);

        file.write(reinterpret_cast<const char*>(padding.data()), padding.size());

    }

    file.close();

    return true;

}



bool loadBMP(const std::string& filename, std::vector<uint8_t>& imageData, int& width, int& height) {

    std::ifstream file(filename, std::ios::binary);

    if (!file) {

        std::cerr << "Erro ao abrir o arquivo." << std::endl;

        return false;

    }



    BMPHeader header;

    file.read(reinterpret_cast<char*>(&header), sizeof(header));

    if (header.signature[0] != 'B' || header.signature[1] != 'M') {

        std::cerr << "Não é um arquivo BMP válido." << std::endl;

        return false;

    }



    width = header.width;

    height = header.height;

    int rowSize = ((width * 3 + 3) & ~3);



    imageData.resize(width * height * 3);

    std::vector<uint8_t> padding(rowSize - width * 3);



    for (int y = 0; y < height; ++y) {

        file.read(reinterpret_cast<char*>(&imageData[y * width * 3]), width * 3);

        file.read(reinterpret_cast<char*>(padding.data()), padding.size());

    }

    file.close();

    return true;

}



void convertToGrayscale(std::vector<uint8_t>& imageData, int width, int height) {

    for (int i = 0; i < width * height; ++i) {

        int idx = i * 3;

        uint8_t r = imageData[idx];

        uint8_t g = imageData[idx + 1];

        uint8_t b = imageData[idx + 2];

        uint8_t gray = static_cast<uint8_t>(r * 0.298 + g * 0.587 + b * 0.114);

        imageData[idx] = gray;

        imageData[idx + 1] = gray;

        imageData[idx + 2] = gray;

    }

}



void measurePerformance(int numImages, const std::string& inputFilename, const std::string& outputFilename) {

    int width, height;

    std::vector<uint8_t> imageData;



    if (!loadBMP(inputFilename, imageData, width, height)) {

        std::cerr << "Erro ao carregar a imagem de entrada." << std::endl;

        return;

    }



    auto start = std::chrono::high_resolution_clock::now();



    for (int i = 0; i < numImages; ++i) {

        std::vector<uint8_t> imageCopy = imageData;

        convertToGrayscale(imageCopy, width, height);

        saveBMP(outputFilename + std::to_string(i) + ".bmp", imageCopy, width, height);

    }



    auto end = std::chrono::high_resolution_clock::now();

    std::chrono::duration<double> elapsed = end - start;



    std::cout << "Tempo para processar " << numImages << " imagens: " << elapsed.count() << " segundos." << std::endl;

}



int main() {

    std::string inputFilename = "teste.bmp";

    std::string outputFilename = "imagem cinza_";



    std::cout << "Metricas de tempo de execucao:" << std::endl;



    measurePerformance(1, inputFilename, outputFilename);

    measurePerformance(10, inputFilename, outputFilename);

    measurePerformance(100, inputFilename, outputFilename);

    measurePerformance(1000, inputFilename, outputFilename);



    return 0;

}