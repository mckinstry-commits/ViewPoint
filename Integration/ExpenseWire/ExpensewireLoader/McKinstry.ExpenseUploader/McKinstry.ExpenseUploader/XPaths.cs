using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace McKinstry.ExpenseUploader
{
    static class XPaths
    {
        static public string EXPENSES = "//ExpenseWire/SendDataTransaction/Expense/Search/Expense";
        static public string EMPLOYEENUMBER = "User/ExternalID";
        static public string EMPLOYEECOMPANY = "Department/DivisionGLPrefix";
        static public string EMPLOYEEEMAIL = "User/UserID";
        static public string INVOICENUMBER = "Ref/ID";
        static public string DEPARTMENT = "Department/GLPrefix";
        static public string JOBNUMBER = "Customer/ExternalID";
        static public string PAYITEM = "Project/ExternalID";
        static public string BATCHNUMBER = "//ExpenseWire/DataTransaction/Expense/Search/Batch/BatchNumber";

    }
}
