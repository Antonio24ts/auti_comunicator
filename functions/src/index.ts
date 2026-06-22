import * as admin from "firebase-admin";
import { defineSecret } from "firebase-functions/params";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { setGlobalOptions } from "firebase-functions/v2";
import { Resend } from "resend";

admin.initializeApp();

setGlobalOptions({
  region: "europe-west1",
  maxInstances: 10,
});

const resendApiKey = defineSecret("RESEND_API_KEY");
const requestsToEmail = defineSecret("REQUESTS_TO_EMAIL");
const requestsFromEmail = defineSecret("REQUESTS_FROM_EMAIL");

type RequestType = "pictogram" | "game" | "category" | "bug" | "other";

const allowedTypes: RequestType[] = [
  "pictogram",
  "game",
  "category",
  "bug",
  "other",
];

export const sendAppRequest = onCall(
  {
    region: "europe-west1",
    secrets: [resendApiKey, requestsToEmail, requestsFromEmail],
    timeoutSeconds: 30,
    memory: "256MiB",
  },
  async (request) => {
    const data = request.data ?? {};

    const type = String(data.type ?? "").trim() as RequestType;
    const message = String(data.message ?? "").trim();
    const childName = String(data.childName ?? "").trim();
    const platform = String(data.platform ?? "").trim();
    const appVersion = String(data.appVersion ?? "").trim();

    if (!allowedTypes.includes(type)) {
      throw new HttpsError(
        "invalid-argument",
        "Tipo de solicitud no válido."
      );
    }

    if (message.length < 10) {
      throw new HttpsError(
        "invalid-argument",
        "La solicitud debe tener al menos 10 caracteres."
      );
    }

    if (message.length > 800) {
      throw new HttpsError(
        "invalid-argument",
        "La solicitud no puede superar 800 caracteres."
      );
    }

    if (childName.length > 80) {
      throw new HttpsError(
        "invalid-argument",
        "El nombre es demasiado largo."
      );
    }

    const now = admin.firestore.FieldValue.serverTimestamp();

    const requestDocument = {
      type,
      message,
      childName: childName || "Sin nombre",
      platform: platform || "unknown",
      appVersion: appVersion || "unknown",
      createdAt: now,
      status: "new",
    };

    const docRef = await admin
      .firestore()
      .collection("app_requests")
      .add(requestDocument);

    const typeLabel = getRequestTypeLabel(type);
    const safeChildName = escapeHtml(childName || "Sin nombre");
    const safeMessage = escapeHtml(message);
    const safePlatform = escapeHtml(platform || "unknown");
    const safeAppVersion = escapeHtml(appVersion || "unknown");

    const html = `
      <div style="font-family: Arial, sans-serif; line-height: 1.45;">
        <h2>Nueva solicitud desde la app</h2>

        <p><strong>ID:</strong> ${docRef.id}</p>
        <p><strong>Niño/a:</strong> ${safeChildName}</p>
        <p><strong>Tipo:</strong> ${escapeHtml(typeLabel)}</p>
        <p><strong>Plataforma:</strong> ${safePlatform}</p>
        <p><strong>Versión app:</strong> ${safeAppVersion}</p>

        <hr />

        <p><strong>Mensaje:</strong></p>
        <p style="white-space: pre-wrap;">${safeMessage}</p>
      </div>
    `;

    const text = [
      "Nueva solicitud desde la app",
      "",
      `ID: ${docRef.id}`,
      `Niño/a: ${childName || "Sin nombre"}`,
      `Tipo: ${typeLabel}`,
      `Plataforma: ${platform || "unknown"}`,
      `Versión app: ${appVersion || "unknown"}`,
      "",
      "Mensaje:",
      message,
    ].join("\n");

    const resend = new Resend(resendApiKey.value());

    const emailResult = await resend.emails.send({
      from: requestsFromEmail.value(),
      to: [requestsToEmail.value()],
      subject: `Nueva solicitud: ${typeLabel}`,
      html,
      text,
    });

    if (emailResult.error) {
      await docRef.update({
        status: "email_error",
        emailError: JSON.stringify(emailResult.error),
      });

      throw new HttpsError(
        "internal",
        "La solicitud se guardó, pero no se pudo enviar el email."
      );
    }

    await docRef.update({
      status: "sent",
      emailId: emailResult.data?.id ?? null,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      ok: true,
      requestId: docRef.id,
    };
  }
);

function getRequestTypeLabel(type: RequestType): string {
  switch (type) {
    case "pictogram":
      return "Pictograma";
    case "game":
      return "Juego";
    case "category":
      return "Categoría";
    case "bug":
      return "Error";
    case "other":
      return "Otro";
  }
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}