using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Threading;

namespace DataEncryptionSample.Helpers
{
    /// <summary>
    /// Helper for managing Task threads in WPF (WPF controls must be called from the UI thread)
    /// </summary>
    public static class RunIn
    {
        /// <summary>
        /// Like Task.Run(action) but with exception logging
        /// </summary>
        public static Task Background(Action action)
        {
            return Task.Run(() =>
            {
                try
                {
                    action.Invoke();
                }
                catch (Exception ex)
                {
                    Log.Error($"[BackgroundEx]\t{ex.Message}", ex);
                }
            });
        }

        /// <summary>
        /// call on UI Thread (WPF controls must be called from the UI thread)
        /// use like Task.Run(action) but to get back onto the UI thread
        /// </summary>
        public static void UI(Action action)
        {
            try
            {
                if (Thread.CurrentThread.ManagedThreadId == 1)
                {
                    action.Invoke();
                }
                else
                {
                    Application.Current.Dispatcher.Invoke(action, DispatcherPriority.Render);
                }
            }
            catch (Exception ex)
            {
                Log.Error($"[UiEx]\t{ex.Message}", ex);
            }
        }
    }
}
