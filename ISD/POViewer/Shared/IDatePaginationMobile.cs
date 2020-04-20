
using Microsoft.VisualBasic;
  
namespace POViewer.UI
{

  

    public interface IDatePaginationMobile {

#region Interface Properties
        System.Web.UI.WebControls.DropDownList _IntervalDropdown {get;}
                
        IThemeButtonMobile NextPageInterval {get;}
                
        System.Web.UI.WebControls.Literal PageTitle {get;}
                
        IThemeButtonMobile PreviousPageInterval {get;}
                
        System.Web.UI.WebControls.Literal StartDate1 {get;}
                
      bool Visible {get; set;}
      string ID {get; set;}
         
      System.Web.UI.WebControls.DropDownList IntervalDropdown {get;}            
                              
      string Interval {get; set;}
      void ProcessPreviousPeriod();
      void ProcessPreviousPagePeriod(int periodsShown);
      void ProcessNextPeriod();
      void ProcessNextPagePeriod(int periodsShown);
      void SetPeriodsShown(int periodsShown);
      string FirstStartDate {get; set;}
        

#endregion

    }

  
}
  