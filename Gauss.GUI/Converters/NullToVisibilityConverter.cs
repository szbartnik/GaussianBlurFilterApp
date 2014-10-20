using System;
using System.Globalization;
using System.Windows;
using System.Windows.Data;

namespace Gauss.GUI.Converters
{
    public class NullToVisibilityConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            var param = parameter as string;
            bool isNull;

            if (value is string)
                isNull = string.IsNullOrWhiteSpace(value as string);
            else
                isNull = value == null;

            if (param != null && param == "Inverse")
                isNull = !isNull;

            if (param != null && param == "Hide")
                return isNull
                    ? Visibility.Hidden
                    : Visibility.Visible;

            return isNull
                ? Visibility.Collapsed
                : Visibility.Visible;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }

    }
}
