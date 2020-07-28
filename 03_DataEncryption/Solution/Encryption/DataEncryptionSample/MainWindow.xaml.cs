using DataEncryptionSample.Helpers;
using Microsoft.Data.SqlClient;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace DataEncryptionSample
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
            Log.Init(OutputTextBox);
            Runner.InitializeSQLProviders();
        }

        private void SqlButton_Click(object sender, RoutedEventArgs e)
        {
            var decryptFlag = DecryptCheckbox.IsChecked ?? false;
            var unmaskFlag = UnmaskCheckbox.IsChecked ?? false;
            Log.Info($"SQL Decrypt:{decryptFlag}");
            Log.Clear();
            Log.Info($"SQL Unmask:{unmaskFlag}");
            Log.Clear();
            RunIn.Background(async() => 
            { 
                DataTable sda = await Runner.SQL(decryptFlag, unmaskFlag);
                RunIn.UI(() => { showCust.ItemsSource = sda.DefaultView; });
            });
        }

    }
}
