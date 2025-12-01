JandosApp – Checklist de Mecânica

Aplicativo desenvolvido como projeto acadêmico para auxiliar oficinas mecânicas no registro, organização e acompanhamento de checklists de veículos. O app permite cadastrar veículos, adicionar checklists, salvar fotos e gerar registros estruturados, facilitando processos internos e aumentando a confiabilidade das informações coletadas.

# **Alunos: Luis Felipe, Gabriel Jandosa, Gabriel Viscardi, Leonardo Martinho, Enzo Souza**

🚗 Sobre o Projeto

O JandosApp foi criado com o objetivo de digitalizar e simplificar o processo de inspeção de veículos em oficinas mecânicas.
Ele permite que o mecânico registre informações importantes durante o atendimento, incluindo:

Dados do veículo

Checklist de itens avaliados

Observações gerais

Upload de fotos (via Firebase Storage)

Salvamento de dados no Firebase

Acompanhamento rápido do estado do veículo

O app foi desenvolvido para ser simples, rápido e funcional em dispositivos Android.

🛠 Tecnologias Utilizadas

Flutter (Dart)

Firebase Authentication

Firebase Firestore

Firebase Storage

Provider para gerenciamento de estado

Material Design

📸 Funcionalidades
✔️ Autenticação

Login com e-mail e senha

Registro de novos usuários

✔️ Cadastro de Veículos

Marca

Modelo

Placa

Observações

✔️ Checklist Completo

Itens de verificação pré-cadastrados

Seleção por checkboxes

Campo de descrição adicional

✔️ Upload de Fotos

Tira foto ou seleciona da galeria

Armazena no Firebase Storage

Vinculação automática ao veículo / checklist

✔️ Histórico

Listagem de todos checklists feitos

Detalhamento de cada inspeção

📂 Estrutura do Projeto
/lib
 ├── models/
 ├── providers/
 ├── screens/
 ├── services/
 ├── widgets/


models/ → Modelos de dados

services/ → Conexão Firebase e regras de negócio

screens/ → Telas do app

widgets/ → Componentes reutilizáveis

providers/ → Lógica de estado
