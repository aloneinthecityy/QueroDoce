const { setGlobalOptions } = require("firebase-functions");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { getFirestore } = require("firebase-admin/firestore");
const { initializeApp } = require("firebase-admin/app");

initializeApp();
setGlobalOptions({ maxInstances: 10 });

const MENSAGENS = {
  // Fluxo entrega em casa
  aceito: {
    title: "Pedido confirmado! 🎉",
    body: "Seu pedido foi aceito pelo restaurante.",
  },
  em_preparacao: {
    title: "Em preparação 👨‍🍳",
    body: "O restaurante está preparando seu pedido.",
  },
  saiu_para_entrega: {
    title: "Saiu para entrega! 🛵",
    body: "Seu pedido está a caminho!",
  },
  entregue: {
    title: "Pedido entregue! 😋",
    body: "Bom apetite! Obrigado por escolher o QueroDoce.",
  },
  // Fluxo retirada
  pronto: {
    title: "Pedido pronto! 🎁",
    body: "Seu pedido está pronto para retirada!",
  },
};

exports.onPedidoStatusChanged = onDocumentUpdated(
  "pedidos/{pedidoId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    // Ignora se o status não mudou
    if (before.status === after.status) return;

    const msg = MENSAGENS[after.status];
    if (!msg) return;

    // Busca o token FCM do cliente
    const idCliente = after.idCliente?.toString();
    if (!idCliente) return;

    const userDoc = await getFirestore()
      .collection("users")
      .doc(idCliente)
      .get();

    const token = userDoc.data()?.fcmToken;
    if (!token) return;

    // Envia a notificação
    await getMessaging().send({
      token,
      notification: msg,
      data: { pedidoId: event.params.pedidoId },
      android: { priority: "high" },
    });

    console.log(`Notificação enviada para cliente ${idCliente}: ${after.status}`);
  }
);