using System;
using System.IO;
using System.Linq;
using System.Windows;
using System.Windows.Media;
using Gauss.GUI.Core;
using Gauss.GUI.Infrastructure;
using Gauss.GUI.Models;

namespace Gauss.GUI.ViewModels
{
    public sealed partial class MainWindowViewModel : ViewModelBase
    {
        #region Commands

        public RelayCommand GenerateBlurredImageCommand { get; private set; }
        public RelayCommand<bool> IsThreadAutodetectCheckedCommand { get; private set; }

        #endregion

        #region Properties

        public byte[] MainPanelImage
        {
            get { return _mainPanelImage; }
            private set
            {
                if (Equals(value, _mainPanelImage)) return;
                _mainPanelImage = value;
                OnPropertyChanged();
            }
        }
        private byte[] _mainPanelImage;

        public SolidColorBrush ImageDropContainerBackground
        {
            get { return _imageDropContainerBackground; }
            private set
            {
                if (!Equals(value, _imageDropContainerBackground))
                {
                    _imageDropContainerBackground = value;
                    OnPropertyChanged();
                }
            }
        }
        private SolidColorBrush _imageDropContainerBackground;

        public string MainPanelDescription
        {
            get { return _mainPanelDescription; }
            set
            {
                if (value != _mainPanelDescription)
                {
                    _mainPanelDescription = value;
                    OnPropertyChanged();
                }
            }
        }
        private string _mainPanelDescription;

        public int NumberOfThreads
        {
            get { return _numberOfThreads; }
            set
            {
                if (value.Equals(_numberOfThreads)) return;
                _numberOfThreads = value;
                OnPropertyChanged();
            }
        }
        private int _numberOfThreads;

        public TimeSpan GenerationTime
        {
            get { return _generationTime; }
            set
            {
                if (value.Equals(_generationTime)) return;
                _generationTime = value;
                OnPropertyChanged();
            }
        }
        private TimeSpan _generationTime;

        public int BlurLevel
        {
            get { return _blurLevel; }
            set
            {
                if (value == _blurLevel) return;
                _blurLevel = value;
                OnPropertyChanged();
            }
        }
        private int _blurLevel;

        public GeneratingLibrary GeneratingLibrary
        {
            get { return _generatingLibrary; }
            set
            {
                if (value == _generatingLibrary) return;
                _generatingLibrary = value;
                OnPropertyChanged();
            }
        }
        private GeneratingLibrary _generatingLibrary;

        #endregion

        #region Constructor

        public MainWindowViewModel()
        {
            InitializeCommands();
            InitializeProperties();
        }

        private void InitializeCommands()
        {
            GenerateBlurredImageCommand = new RelayCommand(() =>
            {
                if (ImageManager == null) return;
                ImageManager.GenerateBlurredImage(new ComputingProcessImageParameters
                {
                    NumberOfThreads = NumberOfThreads,
                    BlurLevel = BlurLevel,
                    GeneratingLibrary = GeneratingLibrary,
                });
            });

            IsThreadAutodetectCheckedCommand = new RelayCommand<bool>(isChecked =>
            {
                if (isChecked)
                {
                    NumberOfThreads = Environment.ProcessorCount;
                }
            });
        }

        #endregion

        private void InitializeProperties()
        {
            NumberOfThreads = 1;
            BlurLevel = 40;
            GeneratingLibrary = GeneratingLibrary.ASM;

            SetDropImageZoneState(DropImagesZoneState.Idle);
        }

        private GaussImageManager ImageManager { get; set; }

        private void SetDropImageZoneState(DropImagesZoneState imagesZoneState)
        {
            Color colorToSet;
            string textToSet;

            switch (imagesZoneState)
            {
                case DropImagesZoneState.Idle:
                    colorToSet = Colors.WhiteSmoke;
                    textToSet = "Drop your BMP files here!";
                    break;
                case DropImagesZoneState.Valid:
                    colorToSet = Colors.DarkSeaGreen;
                    textToSet = "Now drop the files here!";
                    break;
                case DropImagesZoneState.Invalid:
                    colorToSet = Colors.PaleVioletRed;
                    textToSet = "Only BMP files are acceptable!";
                    break;
                case DropImagesZoneState.Dropped:
                    colorToSet = Colors.WhiteSmoke;
                    textToSet = String.Empty;
                    break;
                default:
                    throw new NotImplementedException();
            }

            ImageDropContainerBackground = new SolidColorBrush(colorToSet);
            MainPanelDescription = textToSet;
        }

        #region GUI Events

        public void OnImageDragOver(bool areImagesValid)
        {
            SetDropImageZoneState(areImagesValid ? DropImagesZoneState.Valid : DropImagesZoneState.Invalid);
        }

        public void OnImageDragLeave()
        {
            SetDropImageZoneState(DropImagesZoneState.Idle);
        }

        public void OnImageDrop(DragEventArgs dragEventArgs)
        {
            SetDropImageZoneState(DropImagesZoneState.Dropped);

            var filenames = dragEventArgs.Data.GetData(DataFormats.FileDrop, true) as string[];
            ImageManager = new GaussImageManager(filenames);

            try
            {
                MainPanelImage = File.ReadAllBytes(filenames.First());
            }
            catch (Exception e)
            {
                MessageBox.Show(e.Message);
                SetDropImageZoneState(DropImagesZoneState.Idle);
            }
        }

        #endregion
    }
}