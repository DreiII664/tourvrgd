Este é o código fonte do tour virtul da UNIPAMPA feito em GDscript.

# Instalação e execução do código fonte
- clone o repositório usando o comando na pasta de sua preferência
```
git clone https://github.com/DreiII664/tourvrgd.git
```
- Instale o godot 3 na versão mais recente: https://godotengine.org/download/3.x/windows/
- abra o godot e importe o projeto a partir do arquivo "project.godot" deste repositório.

para compilar o código para meta quest, conecte um cabo USB ao Meta Quest e espere aparecer um ícone no canto superior direito do editor. (modo desenvolvedor deve estar habilitado no headset, além de a preset android correta estar selecionada como runnable na janela Export)
Se estiver rodando o apk no meta quest, ou dispositivos android, dê permissão para o app acessar arquivos do aparelho para armazenar as imagens do tour.

# Integração com o banco de dados
Nesta atualização, o tour na versão godot está adaptado para usar o banco de dados da versão three.js do tour da unipampa, além das diversas mudanças nas cenas para comportar corretamente a posição dos hotspots e rotação das imagens.