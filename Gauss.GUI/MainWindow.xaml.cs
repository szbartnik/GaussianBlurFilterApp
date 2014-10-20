using System.Runtime.InteropServices;
using System.Windows;

namespace Gauss.GUI
{
    public partial class MainWindow : Window
    {
        [DllImport("Gauss.ASM.dll")]
        public static extern int GetInt(int a, int b);

        public MainWindow()
        {
            InitializeComponent();
            MessageBox.Show(GetInt(2, 3).ToString());
        }
    }
}
