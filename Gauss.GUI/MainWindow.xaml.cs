using System.Runtime.InteropServices;
using System.Windows;

namespace Gauss.GUI
{
    public partial class MainWindow : Window
    {
        [DllImport("Gauss.ASM.dll")] private static extern int AddASM(int a, int b);
        [DllImport("Gauss.CPP.dll")] private static extern int AddCPP(int a, int b);

        public MainWindow()
        {
            InitializeComponent();
        }

        private void Button_Click(object sender, RoutedEventArgs e)
        {
            MessageBox.Show(string.Format("ASM: {0}, CPP: {1}", AddASM(2, 3).ToString(), AddCPP(2, 3).ToString()));
        }
    }
}
