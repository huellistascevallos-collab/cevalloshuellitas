// Edge Function: notificar-adopcion
// Trigger: INSERT en tabla solicitudes_adopcion
// Propósito: Enviar push FCM al dueño de la mascota cuando alguien solicita adoptarla.
//
// DESPLIEGUE:
//   1. Instalar Supabase CLI: npm install -g supabase
//   2. supabase login
//   3. supabase link --project-ref TU_PROJECT_REF
//   4. supabase functions deploy notificar-adopcion
//
// VARIABLES DE ENTORNO (agregar en Supabase Dashboard → Settings → Edge Functions):
//   FIREBASE_SERVER_KEY = tu Server Key de Firebase (Configuración proyecto → Cloud Messaging → Legacy API)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  try {
    const body = await req.json();
    
    // El payload viene del Database Webhook configurado en Supabase
    const record = body?.record;
    if (!record) {
      return new Response("No record", { status: 400 });
    }

    const soliId  = record.soli_id;
    const mascId  = record.masc_id;
    const soliEstado = record.soli_estado;

    // Solo procesar solicitudes Pendientes nuevas
    if (soliEstado !== "Pendiente") {
      return new Response("No es Pendiente", { status: 200 });
    }

    // Crear cliente Supabase con service_role para leer sin restricciones RLS
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // 1. Obtener datos completos de la solicitud (mascota + solicitante)
    const { data: solicitud, error: errSoli } = await supabase
      .from("solicitudes_adopcion")
      .select(`
        soli_id,
        mascotas(masc_nombre, usua_id),
        usuarios(usua_nombre)
      `)
      .eq("soli_id", soliId)
      .maybeSingle();

    if (errSoli || !solicitud) {
      console.error("Error obteniendo solicitud:", errSoli);
      return new Response("Error solicitud", { status: 500 });
    }

    const mascota      = solicitud.mascotas as any;
    const solicitante  = solicitud.usuarios as any;
    const duenioId     = mascota?.usua_id;
    const mascNombre   = mascota?.masc_nombre ?? "tu mascota";
    const solNombre    = solicitante?.usua_nombre ?? "Alguien";

    if (!duenioId) {
      return new Response("Sin dueño", { status: 200 });
    }

    // 2. Obtener el token FCM del dueño
    const { data: duenio, error: errDuenio } = await supabase
      .from("usuarios")
      .select("fcm_token, usua_nombre")
      .eq("usua_id", duenioId)
      .maybeSingle();

    if (errDuenio || !duenio?.fcm_token) {
      console.log("Dueño sin token FCM:", duenioId);
      return new Response("Sin token FCM", { status: 200 });
    }

    const fcmToken = duenio.fcm_token;

    // 3. Enviar push via FCM Legacy API
    const firebaseServerKey = Deno.env.get("FIREBASE_SERVER_KEY")!;
    
    const fcmPayload = {
      to: fcmToken,
      priority: "high",
      notification: {
        title: "🐾 Nueva solicitud de adopción",
        body: `${solNombre} quiere adoptar a ${mascNombre}.`,
        sound: "default",
        badge: "1",
        android_channel_id: "huellitas_citas",
      },
      data: {
        tipo: "adopcion",
        soli_id: soliId,
        masc_id: mascId,
        mascota: mascNombre,
        payload: `adopcion:${soliId}`,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    };

    const fcmResponse = await fetch(
      "https://fcm.googleapis.com/fcm/send",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `key=${firebaseServerKey}`,
        },
        body: JSON.stringify(fcmPayload),
      }
    );

    const fcmResult = await fcmResponse.json();
    console.log("FCM response:", JSON.stringify(fcmResult));

    if (fcmResult.success === 1) {
      console.log(`Push enviada a ${duenio.usua_nombre} (${duenioId})`);
      return new Response(JSON.stringify({ ok: true }), { status: 200 });
    } else {
      console.error("FCM error:", fcmResult);
      return new Response(JSON.stringify({ error: fcmResult }), { status: 500 });
    }

  } catch (e) {
    console.error("Error general:", e);
    return new Response(`Error: ${e}`, { status: 500 });
  }
});
