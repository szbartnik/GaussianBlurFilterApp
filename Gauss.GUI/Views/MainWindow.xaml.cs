using System.Windows;
using Gauss.GUI.Infrastructure;
using Gauss.GUI.ViewModels;

namespace Gauss.GUI.Views
{
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
            DataContext = new MainWindowViewModel();
        }

        private void UIElement_OnDragOver(object sender, DragEventArgs e)
        {
            var areImagesValid = Utils.CheckImagesAreOfType(e, ".BMP");

            var vm = DataContext as MainWindowViewModel;
            if (vm != null)
            {
                vm.OnImageDragOver(areImagesValid);
            }

            if (areImagesValid)
                return;

            e.Effects = DragDropEffects.None;
            e.Handled = true;
        }

        private void UIElement_OnDrop(object sender, DragEventArgs e)
        {
            var vm = DataContext as MainWindowViewModel;
            if (vm != null)
            {
                vm.OnImageDrop(e);
            }
        }

        private void UIElement_OnDragLeave(object sender, DragEventArgs e)
        {
            var vm = DataContext as MainWindowViewModel;
            if (vm != null)
            {
                vm.OnImageDragLeave();
            }
        }
    }
}
