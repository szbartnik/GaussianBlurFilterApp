using System;
using System.IO;
using System.Linq;
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
            var vm = new MainWindowViewModel();
            DataContext = vm;

            // Command line arguments run
            var args = Environment.GetCommandLineArgs();
            if (args.Length != 2) 
                return;

            if(File.Exists(args[1]))
                vm.OnImageDrop(args[1]);
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
                vm.OnImageDrop(e.ToFilesArray().First());
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
