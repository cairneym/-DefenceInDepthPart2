using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Controls;

namespace DataEncryptionSample.Helpers
{
    public static class Log
    {
        private static TextBox _output;

        //Standard Output
        public static void Info(string message) { Write("Info", message); }
        public static void Warning(string message, Exception ex = null) { Write("Warning", message, ex); }
        public static void Error(string message, Exception ex = null) { Write("Error", message, ex); }


        public static void Init(TextBox output)
        {
            Thread.CurrentThread.Name = "UI";
            _output = output;
        }

        public static void Clear()
        {
            if (_output == null) return;
            RunIn.UI(() => { _output.Text = ""; });
        }

        private static void Write(string level, string message, Exception ex = null)
        {
            //var thread = Thread.CurrentThread.Name ?? Thread.CurrentThread.ManagedThreadId.ToString();

            var text = $"{DateTime.Now:mm:ss.f}\t[{level}]\t{message}";
            if (ex != null) text += Environment.NewLine + ex.Message;

            Write(text);
        }

        private static void Write(string text)
        {
            //Output
            if (_output == null)
            {
                Debug.WriteLine(text);
                return;
            }

            //UI
            RunIn.UI(() =>
            {
                _output.Text += text + Environment.NewLine;
                _output.ScrollToEnd();
            });
        }
    }
}
