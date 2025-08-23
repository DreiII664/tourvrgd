[Acesso ao tour](https://drei664.itch.io/tourvr-unipampa)
# Mudanças no commit 'thread fix'
- correção de erro de vazamento de dados durante a troca de carregamentos na thread secundária.
# Mudanças no commit 'att fotos'
- Modificação no esquema de fotos para usar threads simuladas e SharedArrayBuffer para carregamento assíncrono das fotos.
correção de bugs:
- problemas com carregamento dos textos nos hotspots de informação.
- mudança rápida de um ambiente para outro causava crash, agora não mais.
- correção temporária de erro com threads
- eliminado o problema de o navegador travar ao carregar foto. (usando simulação de 1 thread para carregar fotos no webgl)