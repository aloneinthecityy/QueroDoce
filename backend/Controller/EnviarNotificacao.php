<?php
ob_start();
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

ini_set('display_errors', 0);
error_reporting(E_ALL);

// Chave da conta de serviço do Firebase
// Você vai baixar esse arquivo no Firebase Console
define('FIREBASE_CREDENTIALS', __DIR__ . '/../firebase-credentials.json');
define('FCM_URL', 'https://fcm.googleapis.com/v1/projects/quero-doce-d5f27/messages:send');

$token      = isset($_REQUEST['token'])     ? $_REQUEST['token']     : "";
$titulo     = isset($_REQUEST['titulo'])    ? $_REQUEST['titulo']    : "";
$mensagem   = isset($_REQUEST['mensagem'])  ? $_REQUEST['mensagem']  : "";
$pedidoId   = isset($_REQUEST['pedidoId']) ? $_REQUEST['pedidoId']  : "";
$status     = isset($_REQUEST['status']) ? $_REQUEST['status'] : "";

if (empty($token) || empty($titulo) || empty($mensagem)) {
    ob_end_clean();
    echo json_encode(["Mensagem" => "Parâmetros obrigatórios ausentes"]);
    exit;
}

try {
    $accessToken = getAccessToken();

    $payload = json_encode([
        "message" => [
            "token" => $token,
            "notification" => [
                "title" => $titulo,
                "body"  => $mensagem,
            ],
            "data" => [
                "pedidoId" => $pedidoId,
                "status"   => $status,
            ],
            "android" => [
                "priority" => "high",
            ],
        ]
    ]);

    $ch = curl_init(FCM_URL);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        "Authorization: Bearer " . $accessToken,
        "Content-Type: application/json",
    ]);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    ob_end_clean();

    if ($httpCode === 200) {
        echo json_encode(["Mensagem" => "Notificação enviada com sucesso"]);
    } else {
        echo json_encode([
            "Mensagem" => "Erro ao enviar notificação",
            "detalhe"  => $response,
            "codigo"   => $httpCode,
        ]);
    }
} catch (Exception $e) {
    ob_end_clean();
    echo json_encode(["Mensagem" => "Erro: " . $e->getMessage()]);
}

function getAccessToken() {
    $credentials = json_decode(file_get_contents(FIREBASE_CREDENTIALS), true);

    $now = time();
    $header = base64UrlEncode(json_encode(["alg" => "RS256", "typ" => "JWT"]));
    $payload = base64UrlEncode(json_encode([
        "iss" => $credentials['client_email'],
        "sub" => $credentials['client_email'],
        "aud" => "https://oauth2.googleapis.com/token",
        "iat" => $now,
        "exp" => $now + 3600,
        "scope" => "https://www.googleapis.com/auth/firebase.messaging",
    ]));

    $signingInput = "$header.$payload";
    $privateKey = openssl_pkey_get_private($credentials['private_key']);
    openssl_sign($signingInput, $signature, $privateKey, "SHA256");
    $jwt = "$signingInput." . base64UrlEncode($signature);

    $ch = curl_init("https://oauth2.googleapis.com/token");
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
        "grant_type" => "urn:ietf:params:oauth:grant-type:jwt-bearer",
        "assertion"  => $jwt,
    ]));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    $response = json_decode(curl_exec($ch), true);
    curl_close($ch);

    if (!isset($response['access_token'])) {
        throw new Exception("Erro ao obter access token: " . json_encode($response));
    }

    return $response['access_token'];
}

function base64UrlEncode($data) {
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}