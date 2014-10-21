using System;
using System.IO;
using System.Threading.Tasks;
using System.Windows;
using Gauss.GUI.Infrastructure;
using Gauss.GUI.Models;
using Microsoft.Win32;

namespace Gauss.GUI.ViewModels
{
    public sealed partial class MainWindowViewModel
    {
        #region Commands

        public RelayCommand GenerateBlurredImageCommand { get; private set; }
        public RelayCommand<bool> IsThreadAutodetectCheckedCommand { get; private set; }
        public RelayCommand SaveBlurredImageCommand { get; private set; }
        public RelayCommand NewImageCommand { get; private set; }
        public RelayCommand AbortComputingCommand { get; private set; }

        #endregion

        private void InitializeCommands()
        {
            InitializeIsThreadAutodetectCheckedCommand();
            InitializeGenerateBlurredImageCommand();
            InitializeSaveBlurredImageCommand();
            InitializeNewImageCommand();
        }

        private void InitializeIsThreadAutodetectCheckedCommand()
        {
            IsThreadAutodetectCheckedCommand = new RelayCommand<bool>(isChecked =>
            {
                if (isChecked)
                {
                    NumberOfThreads = Environment.ProcessorCount;
                }
            });
        }

        private void InitializeGenerateBlurredImageCommand()
        {
            GenerateBlurredImageCommand = new RelayCommand(async () =>
            {
                if (ImageManager == null) return;
                ProgramState = ProgramState.Computing;
                _computationStopwatch.Start();

                ImageManager.ImageComputed += ImageManager_ImageComputed;
                await Task.Run(() => ImageManager.GenerateBlurredImageAsync(
                    new ComputingProcessImageParameters
                    {
                        NumberOfThreads = NumberOfThreads,
                        BlurLevel = BlurLevel,
                        GeneratingLibrary = GeneratingLibrary,
                    }
                    ));
            });
        }

        private void InitializeSaveBlurredImageCommand()
        {
            SaveBlurredImageCommand = new RelayCommand(() =>
            {
                var fileNameWithoutExtension = Path.GetFileNameWithoutExtension(_mainPanelImagePath);
                var fileExtension = Path.GetExtension(_mainPanelImagePath);

                // Initialize save file dialog
                var saveFileDialog = new SaveFileDialog
                {
                    FileName =
                        String.Format("{0}_gauss_{1}", fileNameWithoutExtension, DateTime.Now.ToString("yyyyMMddhhmmss")),
                    DefaultExt = fileExtension,
                    Filter = "Bitmap files (.bmp)|*.bmp",
                };

                // Show save file dialog
                var result = saveFileDialog.ShowDialog();

                if (!result.HasValue || !result.Value)
                    return;

                // Save file
                SaveShowingImage(saveFileDialog.FileName);
            });
        }

        private void InitializeNewImageCommand()
        {
            NewImageCommand = new RelayCommand(() =>
            {
                SetDropImageZoneState(DropImagesZoneState.Idle);
                MainPanelImage = null;
                ProgramState = ProgramState.NoImageLoaded;
            });
        }
    }
}
