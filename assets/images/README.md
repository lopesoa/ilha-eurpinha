# 🗺️ Mapa da Ilha

Esta pasta deve conter a imagem do mapa da Ilha Europinha.

## Como Adicionar o Mapa

1. Coloque a imagem do mapa nesta pasta com o nome: `mapa_ilha.png`
2. Formatos aceitos: PNG, JPG, JPEG
3. Resolução recomendada: 1920x1080 ou superior

## Exemplo de Uso no Código

```dart
Image.asset(
  'assets/images/mapa_ilha.png',
  fit: BoxFit.contain,
)
```

## Coordenadas das Casas

As casas são posicionadas usando coordenadas relativas (0 a 1):

- **mapX**: posição horizontal (0 = esquerda, 1 = direita)
- **mapY**: posição vertical (0 = topo, 1 = base)

Exemplo:
- Casa no centro: `mapX: 0.5, mapY: 0.5`
- Casa no canto superior esquerdo: `mapX: 0.1, mapY: 0.1`
- Casa no canto inferior direito: `mapX: 0.9, mapY: 0.9`

## Criando o Mapa

Você pode:

1. **Desenhar um mapa customizado** (recomendado)
   - Use Figma, Canva, ou qualquer editor de imagens
   - Desenhe a ilha com formato aproximado
   - Numere as casas
   - Adicione pontos de referência (porto, trilhas, etc)

2. **Usar uma foto aérea**
   - Tire uma foto da maquete/planta da ilha
   - Edite para deixar clara
   - Adicione números das casas

3. **Screenshot de mapa online**
   - Google Maps / Google Earth
   - Edite para adicionar informações

## Exemplo de Estrutura

```
Ilha Europinha
┌─────────────────────┐
│  🏠1    🏠5    🏠9  │
│                     │
│  🏠2    🏠6   🏠10  │
│                     │
│  🏠3    🏠7   🏠11  │
│                     │
│  🏠4    🏠8   🏠12  │
└─────────────────────┘
```

Substitua isso por um mapa real e bonito! 😊
