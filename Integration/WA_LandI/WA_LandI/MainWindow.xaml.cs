using System;
using System.Collections.Generic;
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

namespace WA_LandI
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        string startDate, endDate;
        public MainWindow()
        {
            InitializeComponent();
        }

        private void startDatePick_SelectedDateChanged(object sender, SelectionChangedEventArgs e)
        {
             startDate = startDatePick.SelectedDate.Value.ToString("MM/dd/yyyy", System.Globalization.CultureInfo.InvariantCulture);
            
        }

        private void genXML_Click(object sender, RoutedEventArgs e)
        {

        }

        private void endDatePick_SelectedDateChanged(object sender, SelectionChangedEventArgs e)
        {
            endDate = endDatePick.SelectedDate.Value.ToString("MM/dd/yyyy", System.Globalization.CultureInfo.InvariantCulture);
        }
    }
}
