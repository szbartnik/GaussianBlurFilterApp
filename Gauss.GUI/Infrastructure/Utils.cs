using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Windows;

namespace Gauss.GUI.Infrastructure
{
    public static class Utils
    {
        public static bool CheckImagesAreOfType(DragEventArgs e, string extension)
        {
            if (!e.Data.GetDataPresent(DataFormats.FileDrop, true))
                return false;

            var filenames = e.Data.GetData(DataFormats.FileDrop, true) as string[];

            if (filenames.Any(filename => Path.GetExtension(filename).ToUpperInvariant() != extension.ToUpperInvariant()))
                return false;

            return true;
        }

        public static IEnumerable<string> ToFilesArray(this DragEventArgs eventArgs)
        {
            return eventArgs.Data.GetData(DataFormats.FileDrop, true) as string[];
        }
    }
}
