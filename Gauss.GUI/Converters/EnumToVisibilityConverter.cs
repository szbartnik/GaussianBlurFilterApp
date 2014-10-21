using System;
using System.Globalization;
using System.Linq;
using System.Windows;
using System.Windows.Data;

namespace Gauss.GUI.Converters
{
    [ValueConversion(typeof(Enum), typeof(Visibility))]
    public class EnumToVisibilityConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value == null || parameter == null) 
                return Visibility.Collapsed;

            string enumValue = value.ToString();
            var targetValues = parameter.ToString().Split('|');

            bool outputValue = targetValues.Any(x => x.Equals(enumValue, StringComparison.InvariantCulture));

            return outputValue ? Visibility.Visible : Visibility.Collapsed;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value == null || parameter == null) 
                return null;

            bool useValue = (bool)value;
            string targetValue = parameter.ToString();

            if (useValue) 
                return Enum.Parse(targetType, targetValue);

            return null;
        }
    }
}