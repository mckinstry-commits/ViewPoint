using System;

namespace McKinstry.Data.Models.Viewpoint
{
    public class Filter
    {
        public Filter (int column, dynamic criteria1, dynamic criteria2)
        {
            Column = column;
            try
            {
                Criteria1 = criteria1;
            }
            catch (Exception)
            {
            }

            try
            {
                Criteria1 = criteria1;
            }
            catch (Exception)
            {
            }
        }
        public Filter() { }
        public int Column { get; set; }
        public dynamic Criteria1 { get; set; }
        public dynamic Criteria2 { get; set; }
        public object[] _Criteria1 { get; set; }
        public object[] _Criteria2 { get; set; }
    }
}
