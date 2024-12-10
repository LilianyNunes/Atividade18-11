#include <iostream>
#include <fstream>
#include <vector>
#include <cstring>

// Função para ler uma imagem BMP (500x500)
void readImageBMP(const std::string& filename, std::vector<unsigned char>& data, int& width, int& height) {
    std::ifstream file(filename, std::ios::binary);
    if (!file) {
        std::cerr << "Erro ao abrir o arquivo BMP." << std::endl;
        return;
    }

    // Cabeçalho de 54 bytes (14 + 40)
    unsigned char header[54];
    file.read(reinterpret_cast<char*>(header), 54);

    // Largura e altura
    width = *reinterpret_cast<int*>(&header[18]);
    height = *reinterpret_cast<int*>(&header[22]);

    // Verificando se a imagem é 24 bits por pixel
    int bitsPerPixel = *reinterpret_cast<short*>(&header[28]);
    if (bitsPerPixel != 24) {
        std::cerr << "A imagem deve ser 24 bits por pixel." << std::endl;
        return;
    }

    // Tamanho da linha de dados, considerando o padding
    int padding = (4 - (width * 3) % 4) % 4;  // 3 porque cada pixel tem 3 bytes (RGB)
    int rowSize = width * 3 + padding;

    // Lendo os dados de pixel
    data.resize(rowSize * height);
    for (int y = height - 1; y >= 0; --y) {
        file.read(reinterpret_cast<char*>(&data[y * rowSize]), rowSize);
    }

    file.close();
}

// Função para salvar a imagem em formato BMP
void saveImageBMP(const std::string& filename, const std::vector<unsigned char>& data, int width, int height) {
    int padding = (4 - (width * 3) % 4) % 4; // Preenchimento para alinhar as linhas a múltiplos de 4 bytes
    int rowSize = width * 3 + padding;
    int dataSize = rowSize * height;

    // Cabeçalho do arquivo BMP (14 bytes)
    unsigned char fileHeader[14] = {
        'B', 'M',                           // Identificação do arquivo BMP
        0, 0, 0, 0,                         // Tamanho total do arquivo (atualizado depois)
        0, 0,                               // Reservado
        0, 0,                               // Reservado
        54, 0, 0, 0                         // Offset para os dados de pixel
    };

    // Cabeçalho da informação BMP (40 bytes)
    unsigned char infoHeader[40] = {
        40, 0, 0, 0,                        // Tamanho deste cabeçalho
        0, 0, 0, 0,                         // Largura da imagem (atualizado depois)
        0, 0, 0, 0,                         // Altura da imagem (atualizado depois)
        1, 0,                               // Planos (sempre 1)
        24, 0,                              // Bits por pixel (24 para RGB)
        0, 0, 0, 0,                         // Nenhuma compressão
        0, 0, 0, 0,                         // Tamanho dos dados de imagem (atualizado depois)
        0, 0, 0, 0,                         // Resolução horizontal (não usada)
        0, 0, 0, 0,                         // Resolução vertical (não usada)
        0, 0, 0, 0,                         // Número de cores na paleta
        0, 0, 0, 0                          // Todas as cores são importantes
    };

    // Atualizando os cabeçalhos com os tamanhos corretos
    int fileSize = 54 + dataSize;
    std::memcpy(&fileHeader[2], &fileSize, 4);
    std::memcpy(&infoHeader[4], &width, 4);
    std::memcpy(&infoHeader[8], &height, 4);
    std::memcpy(&infoHeader[20], &dataSize, 4);

    // Abrindo o arquivo para escrita
    std::ofstream file(filename, std::ios::out | std::ios::binary);
    if (!file) {
        std::cerr << "Erro ao abrir arquivo para escrita: " << filename << std::endl;
        return;
    }

    // Gravando cabeçalhos
    file.write(reinterpret_cast<const char*>(fileHeader), sizeof(fileHeader));
    file.write(reinterpret_cast<const char*>(infoHeader), sizeof(infoHeader));

    // Gravando os dados dos pixels
    for (int y = height - 1; y >= 0; --y) { // BMP começa do canto inferior
        file.write(reinterpret_cast<const char*>(&data[y * rowSize]), width * 3);
        file.write("\0\0\0", padding); // Adicionando o padding
    }

    file.close();
    std::cout << "Imagem salva como BMP: " << filename << std::endl;
}

// Função para converter uma imagem para tons de cinza
void convertToGray(std::vector<unsigned char>& data, int width, int height) {
    int padding = (4 - (width * 3) % 4) % 4; // Preenchimento para alinhar as linhas a múltiplos de 4 bytes
    int rowSize = width * 3 + padding;

    for (int y = height - 1; y >= 0; --y) {
        for (int x = 0; x < width; ++x) {
            // Índices para os canais RGB
            int pixelIdx = y * rowSize + x * 3;

            unsigned char r = data[pixelIdx + 2]; // Vermelho
            unsigned char g = data[pixelIdx + 1]; // Verde
            unsigned char b = data[pixelIdx + 0]; // Azul

            // Calculando a intensidade de cinza usando a fórmula de luminosidade
            unsigned char gray = static_cast<unsigned char>(r * 0.298 + g * 0.587 + b * 0.114);

            // Substituindo os valores RGB pelo valor de cinza
            data[pixelIdx + 2] = gray; // Vermelho
            data[pixelIdx + 1] = gray; // Verde
            data[pixelIdx + 0] = gray; // Azul
        }
    }
}

int main() {
    std::string inputFilename = "teste.bmp";
    std::string outputFilename = "output.bmp";

    // Dados da imagem
    int width, height;
    std::vector<unsigned char> imageData;

    // Lendo a imagem
    readImageBMP(inputFilename, imageData, width, height);

    // Convertendo a imagem para tons de cinza
    convertToGray(imageData, width, height);

    // Salvando a imagem convertida
    saveImageBMP(outputFilename, imageData, width, height);

    return 0;
}
