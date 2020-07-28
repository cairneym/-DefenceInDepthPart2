using Azure.Core;
using Azure.Identity;
using Azure.Security.KeyVault.Keys;
using Azure.Security.KeyVault.Secrets;
using DataEncryptionSample.Helpers;
using Microsoft.Data.SqlClient;
using Microsoft.Data.SqlClient.AlwaysEncrypted.AzureKeyVaultProvider;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Controls;

namespace DataEncryptionSample
{
    public static class Runner
    {

        public static async Task<DataTable> SQL(bool decryptFlag, bool unmaskFlag )
        {
            if (SQLAccessToken.Token == null) await GetSQLAccessToken(false);

            DataTable res = new DataTable();

            try
            {

                //Connection String Builder
                SqlConnectionStringBuilder builder = new SqlConnectionStringBuilder()
                {
                    DataSource = "<Your server name here>.database.windows.net,1433", //Server
                    InitialCatalog = "WideWorldImporters",
                    Encrypt = true,
                };
                var connectionString = builder.ConnectionString;
                Log.Info($"Connection String: {connectionString}");

                using (SqlConnection connection = new SqlConnection(connectionString))
                {
                    connection.AccessToken = SQLAccessToken.Token; //use JWT Token OR use Authentication method above
                    connection.Open();
                    Log.Info($"ServerVersion:{connection.ServerVersion} State:{connection.State}");

                    using (SqlCommand command = new SqlCommand("Application.GetCustomerInfo", connection))
                    {
                        command.CommandType = CommandType.StoredProcedure;
                        command.Parameters.Add(new SqlParameter("@BypassMasking", unmaskFlag));

                        SqlDataAdapter a = new SqlDataAdapter(command);
                        a.Fill(res);



                        StringBuilder output = new StringBuilder("Table output\n");
                        output.AppendLine("---------------------------------------------");
                        var reader = command.ExecuteReader();
                        while (reader.Read())
                        {
                            var row = DebugRow(reader);
                            output.AppendLine(row);
                        }
                        output.AppendLine("---------------------------------------------");
                        Log.Info(output.ToString());
                    }
                }
            }
            catch (Exception ex)
            {
                Log.Error("Failed to Run", ex);

            }
            return res;
        }

        private static string DebugRow(SqlDataReader reader)
        {
            object[] values = new object[reader.FieldCount];
            reader.GetValues(values);
            var list = values.Select(value => (value is byte[]) ? $"{BitConverter.ToString((byte[])value).Substring(0, 6)}..." : value.ToString());
            return string.Join("\t", list);
        }

        //------------------------------------------------------------------
        // Azure Token
        //------------------------------------------------------------------
        private static AccessToken SQLAccessToken = new AccessToken();

        public static async Task GetSQLAccessToken(bool interactiveFlag)
        {
            SQLAccessToken = await AzureAccessToken("https://database.windows.net/.default", interactiveFlag);
            DebugJwt(SQLAccessToken.Token);
        }

        private static async Task<AccessToken> AzureAccessToken(string scope, bool interactiveFlag)
        {
            try
            {
                var tokenRequestContext = new TokenRequestContext(new[] { scope });
 
                //Method
                var accessToken = (interactiveFlag)
                    ? await new InteractiveBrowserCredential().GetTokenAsync(tokenRequestContext)
                    : await new DefaultAzureCredential(true).GetTokenAsync(tokenRequestContext);

                return accessToken;
            }
            catch (Exception ex)
            {
                Log.Error("Failed to get token", ex);
                return new AccessToken();
            }
        }

        private static void DebugJwt(string token)
        {
            if (token == null) return;

            var parts = token.Split('.');
            //var header = DecodeBase64(parts[0]);
            var payload = DecodeBase64(parts[1]);
            //var signature = parts[2];

            Log.Info($"Token\n-------------------------------------------------\n{payload}\n-------------------------------------------------");
        }

        private static string DecodeBase64(string base64)
        {
            //fix padding for base64 (JWT does not include the == padding to make an even 4 bytes (64bits) while C# FromBase64String requires it)
            if (base64.Length % 4 != 0) base64 += new string('=', 4 - base64.Length % 4);

            byte[] data = Convert.FromBase64String(base64);
            return Encoding.ASCII.GetString(data);
        }
        //------------------------------------------------------------------

    }
}
