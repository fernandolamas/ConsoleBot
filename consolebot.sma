#include <amxmodx>
#include <json>
#include <curl>

#define CURL_BUFFER_SIZE 512

new const g_iTimeBetweenCalls = 30;

new g_iLastCall, bool:g_bIsWorking, CURL:g_cURLHandle, curl_slist:g_cURLHeaders, g_szHostname[129], g_szPassword[15];
new const g_szNetAddress[22] = "YOUR IP ADDRESS";

public plugin_init()
{
    register_plugin("[cURL] Discord !admin Webhook", "1.0", "BESTIA");

    register_clcmd("say !admin", "cmd_admincall");
    register_clcmd("say !sub", "cmd_subcall");
	register_clcmd("say !teams", "cmd_teamcall");
	register_clcmd("say !shuffle", "cmd_shufflecall", ADMIN_CFG);
}

public plugin_cfg()
{
    // Add a delay to wait for the values for g_szHostname and g_szNetAddress
    g_iLastCall = get_systime();
    set_task(10.0, "plugin_cfg_delayed");
}

public plugin_cfg_delayed()
{
    get_cvar_string("hostname", g_szHostname, charsmax(g_szHostname));
    get_cvar_string("sv_password", g_szPassword, charsmax(g_szPassword));
}

public plugin_end()
{
    if (g_cURLHandle)
    {
        curl_easy_cleanup(g_cURLHandle);
        g_cURLHandle = CURL:0;
    }
    if (g_cURLHeaders)
    {
        curl_slist_free_all(g_cURLHeaders);
        g_cURLHeaders = curl_slist:0;
    }
}

// Replace MB Chars with "."
_fixName(name[])
{
    new i = 0;
    while (name[i] != 0)
    {
        if (!(0 <= name[i] <= 255))
        {
            name[i] = '.';
        }
        i++;
    }
}

public cmd_subcall(id)
{
  static iCurTime;
  
  if(get_user_team(id) == 1 || get_user_team(id) == 2)
  {
    
 
    if (!g_bIsWorking && ((iCurTime = get_systime()) - g_iLastCall) > g_iTimeBetweenCalls)
    {
        g_iLastCall = iCurTime;

        static szName[32], szAuthId[35], szBuffer[129], JSON:jEmbeds[1], JSON:jEmbed, JSON:jWebhook;
		static g_szURL[] = "A discord webhook";
        get_user_name(id, szName, charsmax(szName)); //obtiene name del player
        get_user_authid(id, szAuthId, charsmax(szAuthId)); //obtiene steam id
        _fixName(szName);
        
        
        // Create array of embed objects
        jEmbed = json_create();
        json_set_string(jEmbed, "title", g_szHostname);
        formatex(szBuffer, charsmax(szBuffer), "Conectate: steam://connect/%s/%s", g_szNetAddress, g_szPassword);
        json_set_string(jEmbed, "description", szBuffer);
        jEmbeds[0] = jEmbed;
        
        // Create webhook request object
        jWebhook = json_create();  
        formatex(szBuffer, charsmax(szBuffer), "%s NECESITA UN REEMPLAZO por favor entra!", szName);
        json_set_string(jWebhook, "content", szBuffer);
        json_set_array(jWebhook, "embeds", jEmbeds, sizeof(jEmbeds), _, JSON_Object);
      
        // Send It
        postJSON(g_szURL, jWebhook);
        json_destroy(jWebhook);
        // json_destroy(jEmbed); // Destroyed in chain
    
        client_print(0,print_chat, "%s necesita ser reemplazado, por favor entra en su lugar", szName)
        
      }else client_print(id, print_chat, " ** Solo se puede pedir sub cada %d Segundos **", g_iTimeBetweenCalls);
    
   }else client_print(id, print_chat, " no estas en ningun equipo")
  
  return PLUGIN_HANDLED
}

public cmd_admincall(id)
{
    static iCurTime;

    if (!g_bIsWorking && ((iCurTime = get_systime()) - g_iLastCall) > g_iTimeBetweenCalls)
    {
        g_iLastCall = iCurTime;

        static szName[32], szAuthId[35], szBuffer[129], JSON:jEmbeds[1], JSON:jEmbed, JSON:jWebhook;
		static g_szURL[] = "A discord webhook goes here";
        get_user_name(id, szName, charsmax(szName)); //obtiene name del player
        get_user_authid(id, szAuthId, charsmax(szAuthId)); //obtiene steam id
        _fixName(szName);

        // Create array of embed objects
        jEmbed = json_create();
        json_set_string(jEmbed, "title", g_szHostname);
        formatex(szBuffer, charsmax(szBuffer), "Conectate: steam://connect/%s/%s", g_szNetAddress, g_szPassword);
        json_set_string(jEmbed, "description", szBuffer);
        jEmbeds[0] = jEmbed;

        // Create webhook request object
        jWebhook = json_create();
        formatex(szBuffer, charsmax(szBuffer), "^"%s^" esta llamando a un administrador.", szName);
        json_set_string(jWebhook, "content", szBuffer);
        json_set_array(jWebhook, "embeds", jEmbeds, sizeof(jEmbeds), _, JSON_Object);

        // Send It
        postJSON(g_szURL, jWebhook);
        json_destroy(jWebhook);
        // json_destroy(jEmbed); // Destroyed in chain
    }
    else client_print(id, print_chat, " ** Admins pueden ser llamados cada 30 segundos **", g_iTimeBetweenCalls);

    return PLUGIN_HANDLED;
}

public cmd_teamcall(id)
{
    curl_request_teams();
}

public cmd_shufflecall(id,level)
{
	if(get_user_flags(id) & level)
	{
		static szBuffer[129], JSON:jWebhook;
		static g_szURL[] = "A discord webhook goes here";

        jWebhook = json_create();
        formatex(szBuffer, charsmax(szBuffer), "!rcon brshuffle");
        json_set_string(jWebhook, "content", szBuffer);
        console_print(0,"Pidiendo shuffle al discord...");
		
		
		postJSON(g_szURL, jWebhook);
        json_destroy(jWebhook);
	}
}


//fin de los comandos

postJSON(const link[], JSON:jObject)
{
    if (!g_cURLHandle)
    {
        if (!(g_cURLHandle = curl_easy_init()))
        {
            log_amx("[Fatal Error] Cannot Init cURL Handle.");
            pause("d");
            return;
        }
        if (!g_cURLHeaders)
        {
            // Init g_cURLHeaders with "Content-Type: application/json"
            g_cURLHeaders = curl_slist_append(g_cURLHeaders, "Content-Type: application/json");
            curl_slist_append(g_cURLHeaders, "User-Agent: 822_AMXX_PLUGIN/1.0"); // User-Agent
            curl_slist_append(g_cURLHeaders, "Connection: Keep-Alive"); // Keep-Alive
        }

        // Static Options
        curl_easy_setopt(g_cURLHandle, CURLOPT_SSL_VERIFYPEER, 0);
        curl_easy_setopt(g_cURLHandle, CURLOPT_SSL_VERIFYHOST, 0);
        curl_easy_setopt(g_cURLHandle, CURLOPT_SSLVERSION, CURL_SSLVERSION_TLSv1);
        curl_easy_setopt(g_cURLHandle, CURLOPT_FAILONERROR, 0);
        curl_easy_setopt(g_cURLHandle, CURLOPT_FOLLOWLOCATION, 0);
        curl_easy_setopt(g_cURLHandle, CURLOPT_FORBID_REUSE, 0);
        curl_easy_setopt(g_cURLHandle, CURLOPT_FRESH_CONNECT, 0);
        curl_easy_setopt(g_cURLHandle, CURLOPT_CONNECTTIMEOUT, 10);
        curl_easy_setopt(g_cURLHandle, CURLOPT_TIMEOUT, 10);
        curl_easy_setopt(g_cURLHandle, CURLOPT_HTTPHEADER, g_cURLHeaders);
        curl_easy_setopt(g_cURLHandle, CURLOPT_POST, 1);
    }

    static szPostdata[513];
    json_encode(jObject, szPostdata, charsmax(szPostdata));
    //log_amx("[DEBUG] POST: %s", szPostdata);

    curl_easy_setopt(g_cURLHandle, CURLOPT_URL, link);
    curl_easy_setopt(g_cURLHandle, CURLOPT_COPYPOSTFIELDS, szPostdata);

    g_bIsWorking = true;
    curl_easy_perform(g_cURLHandle, "postJSON_done");
}

public postJSON_done(CURL:curl, CURLcode:code)
{
    g_bIsWorking = false;
    if (code == CURLE_OK)
    {
        static statusCode;
        curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, statusCode);
        if (statusCode >= 400)
        {
            log_amx("[Error] HTTP Error: %d", statusCode);
        }
    }
    else
    {
        log_amx("[Error] cURL Error: %d", code);
        curl_easy_cleanup(g_cURLHandle);
        g_cURLHandle = CURL:0;
    }
} 

public curl_request_teams()
{
	new data[1]
	new CURL:curl = curl_easy_init()
	curl_easy_setopt(curl, CURLOPT_BUFFERSIZE, CURL_BUFFER_SIZE)
	curl_easy_setopt(curl, CURLOPT_URL, "A !teams endpoint goes here")
	curl_easy_setopt(curl, CURLOPT_WRITEDATA, data[0])
	curl_easy_perform(curl, "complite", data, sizeof(data))
}

public complite(CURL:curl, CURLcode:code, data[])
{
	if(code == CURLE_WRITE_ERROR)
	{
		server_print("transfer aborted")
	}else
	{
     	server_print("curl complete")
	}
	fclose(data[0])
	curl_easy_cleanup(curl)
}
