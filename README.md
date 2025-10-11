# 🚗 JandosApp

Um aplicativo Flutter criado para modernizar e organizar as anotações de manutenção de veículos em oficinas mecânicas.

## 📖 Sobre o Projeto

### 🧩 O Problema
Atualmente, as anotações sobre cada veículo (danos, peças trocadas, serviços realizados) são feitas **manualmente**, o que torna difícil:
- Controlar os serviços executados;
- Consultar históricos de atendimentos antigos;
- Compartilhar informações entre a equipe.

### 💡 A Solução
O **JandosApp** é um **bloco de notas inteligente e compartilhado** entre os **4 mecânicos** e o **administrador** da oficina.

O sistema formaliza e organiza as informações, garantindo que **nenhum detalhe se perca** e que o **histórico de cada cliente/veículo** esteja sempre a um clique de distância.

---

## ⚙️ Funcionalidades Principais

### 📝 Registro Prático
- O mecânico cria um registro ao atender um carro.
- Adiciona detalhes como **amassados (com fotos 📸)**, **peças utilizadas** e **ações realizadas**.

### 🔄 Sincronização Automática
- Tudo o que o mecânico anota é **enviado instantaneamente** para o administrador.
- Mantém todos na **mesma página**, sem perda de dados.

### 📂 Histórico Completo e Acessível
- Mecânicos e administrador podem **filtrar e pesquisar** registros por:
  - Placa do veículo;
  - Nome do cliente;
  - Serviços realizados.
- Permite visualizar o **histórico completo** de manutenções a qualquer momento.

---

## 🧠 Tecnologias Utilizadas
- **Flutter** — framework multiplataforma (Android/iOS/Web);
- **Dart** — linguagem principal do app;
- **Intl** — formatação de datas e números;
- **Provider / Riverpod (dependendo da implementação)** — gerenciamento de estado;
- **Firebase (opcional)** — sincronização em tempo real e armazenamento de fotos.

---

## 🚀 Executando o Projeto

1. **Clone este repositório:**
   ```bash
   git clone https://github.com/luis1010100/JandosApp.git
