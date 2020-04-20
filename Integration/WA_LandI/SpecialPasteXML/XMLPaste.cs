
using System;
using System.Collections.Generic;
using System.Text;
// NOTE: Generated code may require at least .NET Framework 4.5 or .NET Core/Standard 2.0.
/// <remarks/>
[System.SerializableAttribute()]
[System.ComponentModel.DesignerCategoryAttribute("code")]
[System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
[System.Xml.Serialization.XmlRootAttribute(Namespace = "", IsNullable = false)]
public partial class WaPWCPR
{

    private WaPWCPRProjectIntent projectIntentField;

    private WaPWCPRPayroll payrollField;

    /// <remarks/>
    public WaPWCPRProjectIntent projectIntent
    {
        get
        {
            return this.projectIntentField;
        }
        set
        {
            this.projectIntentField = value;
        }
    }

    /// <remarks/>
    public WaPWCPRPayroll payroll
    {
        get
        {
            return this.payrollField;
        }
        set
        {
            this.payrollField = value;
        }
    }
}

/// <remarks/>
[System.SerializableAttribute()]
[System.ComponentModel.DesignerCategoryAttribute("code")]
[System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
public partial class WaPWCPRProjectIntent
{

    private uint intentIdField;

    /// <remarks/>
    public uint intentId
    {
        get
        {
            return this.intentIdField;
        }
        set
        {
            this.intentIdField = value;
        }
    }
}

/// <remarks/>
[System.SerializableAttribute()]
[System.ComponentModel.DesignerCategoryAttribute("code")]
[System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
public partial class WaPWCPRPayroll
{

    private WaPWCPRPayrollPayrollWeek payrollWeekField;

    /// <remarks/>
    public WaPWCPRPayrollPayrollWeek payrollWeek
    {
        get
        {
            return this.payrollWeekField;
        }
        set
        {
            this.payrollWeekField = value;
        }
    }
}

/// <remarks/>
[System.SerializableAttribute()]
[System.ComponentModel.DesignerCategoryAttribute("code")]
[System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
public partial class WaPWCPRPayrollPayrollWeek
{

    private System.DateTime endOfWeekDateField;

    private bool noWorkPerformFlagField;

    private bool amendedFlagField;

    private System.DateTime amendedDateField;

    private WaPWCPRPayrollPayrollWeekEmployees employeesField;

    /// <remarks/>
    [System.Xml.Serialization.XmlElementAttribute(DataType = "date")]
    public System.DateTime endOfWeekDate
    {
        get
        {
            return this.endOfWeekDateField;
        }
        set
        {
            this.endOfWeekDateField = value;
        }
    }

    /// <remarks/>
    public bool noWorkPerformFlag
    {
        get
        {
            return this.noWorkPerformFlagField;
        }
        set
        {
            this.noWorkPerformFlagField = value;
        }
    }

    /// <remarks/>
    public bool amendedFlag
    {
        get
        {
            return this.amendedFlagField;
        }
        set
        {
            this.amendedFlagField = value;
        }
    }

    /// <remarks/>
    [System.Xml.Serialization.XmlElementAttribute(DataType = "date")]
    public System.DateTime amendedDate
    {
        get
        {
            return this.amendedDateField;
        }
        set
        {
            this.amendedDateField = value;
        }
    }

    /// <remarks/>
    public WaPWCPRPayrollPayrollWeekEmployees employees
    {
        get
        {
            return this.employeesField;
        }
        set
        {
            this.employeesField = value;
        }
    }
}

/// <remarks/>
[System.SerializableAttribute()]
[System.ComponentModel.DesignerCategoryAttribute("code")]
[System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
public partial class WaPWCPRPayrollPayrollWeekEmployees
{

    private WaPWCPRPayrollPayrollWeekEmployeesEmployee employeeField;

    /// <remarks/>
    public WaPWCPRPayrollPayrollWeekEmployeesEmployee employee
    {
        get
        {
            return this.employeeField;
        }
        set
        {
            this.employeeField = value;
        }
    }
}

/// <remarks/>
[System.SerializableAttribute()]
[System.ComponentModel.DesignerCategoryAttribute("code")]
[System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
public partial class WaPWCPRPayrollPayrollWeekEmployeesEmployee
{

    private string firstNameField;

    private object midNameField;

    private string lastNameField;

    private uint ssnField;

    private string ethnicityField;

    private string genderField;

    private string veteranStatusField;

    private string address1Field;

    private object address2Field;

    private string cityField;

    private string stateField;

    private uint zipField;

    private decimal grossPayField;

    private decimal ficaField;

    private decimal taxWitholdingField;

    private WaPWCPRPayrollPayrollWeekEmployeesEmployeeOtherDeductions otherDeductionsField;

    private WaPWCPRPayrollPayrollWeekEmployeesEmployeeTradeHoursWages tradeHoursWagesField;

    /// <remarks/>
    public string firstName
    {
        get
        {
            return this.firstNameField;
        }
        set
        {
            this.firstNameField = value;
        }
    }

    /// <remarks/>
    public object midName
    {
        get
        {
            return this.midNameField;
        }
        set
        {
            this.midNameField = value;
        }
    }

    /// <remarks/>
    public string lastName
    {
        get
        {
            return this.lastNameField;
        }
        set
        {
            this.lastNameField = value;
        }
    }

    /// <remarks/>
    public uint ssn
    {
        get
        {
            return this.ssnField;
        }
        set
        {
            this.ssnField = value;
        }
    }

    /// <remarks/>
    public string ethnicity
    {
        get
        {
            return this.ethnicityField;
        }
        set
        {
            this.ethnicityField = value;
        }
    }

    /// <remarks/>
    public string gender
    {
        get
        {
            return this.genderField;
        }
        set
        {
            this.genderField = value;
        }
    }

    /// <remarks/>
    public string veteranStatus
    {
        get
        {
            return this.veteranStatusField;
        }
        set
        {
            this.veteranStatusField = value;
        }
    }

    /// <remarks/>
    public string address1
    {
        get
        {
            return this.address1Field;
        }
        set
        {
            this.address1Field = value;
        }
    }

    /// <remarks/>
    public object address2
    {
        get
        {
            return this.address2Field;
        }
        set
        {
            this.address2Field = value;
        }
    }

    /// <remarks/>
    public string city
    {
        get
        {
            return this.cityField;
        }
        set
        {
            this.cityField = value;
        }
    }

    /// <remarks/>
    public string state
    {
        get
        {
            return this.stateField;
        }
        set
        {
            this.stateField = value;
        }
    }

    /// <remarks/>
    public uint zip
    {
        get
        {
            return this.zipField;
        }
        set
        {
            this.zipField = value;
        }
    }

    /// <remarks/>
    public decimal grossPay
    {
        get
        {
            return this.grossPayField;
        }
        set
        {
            this.grossPayField = value;
        }
    }

    /// <remarks/>
    public decimal fica
    {
        get
        {
            return this.ficaField;
        }
        set
        {
            this.ficaField = value;
        }
    }

    /// <remarks/>
    public decimal taxWitholding
    {
        get
        {
            return this.taxWitholdingField;
        }
        set
        {
            this.taxWitholdingField = value;
        }
    }

    /// <remarks/>
    public WaPWCPRPayrollPayrollWeekEmployeesEmployeeOtherDeductions otherDeductions
    {
        get
        {
            return this.otherDeductionsField;
        }
        set
        {
            this.otherDeductionsField = value;
        }
    }

    /// <remarks/>
    public WaPWCPRPayrollPayrollWeekEmployeesEmployeeTradeHoursWages tradeHoursWages
    {
        get
        {
            return this.tradeHoursWagesField;
        }
        set
        {
            this.tradeHoursWagesField = value;
        }
    }
}

/// <remarks/>
[System.SerializableAttribute()]
[System.ComponentModel.DesignerCategoryAttribute("code")]
[System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
public partial class WaPWCPRPayrollPayrollWeekEmployeesEmployeeOtherDeductions
{

    private WaPWCPRPayrollPayrollWeekEmployeesEmployeeOtherDeductionsOtherDeduction otherDeductionField;

    /// <remarks/>
    public WaPWCPRPayrollPayrollWeekEmployeesEmployeeOtherDeductionsOtherDeduction otherDeduction
    {
        get
        {
            return this.otherDeductionField;
        }
        set
        {
            this.otherDeductionField = value;
        }
    }
}

/// <remarks/>
[System.SerializableAttribute()]
[System.ComponentModel.DesignerCategoryAttribute("code")]
[System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
public partial class WaPWCPRPayrollPayrollWeekEmployeesEmployeeOtherDeductionsOtherDeduction
{

    private string deductionNameField;

    private decimal deductionHourlyAmtField;

    /// <remarks/>
    public string deductionName
    {
        get
        {
            return this.deductionNameField;
        }
        set
        {
            this.deductionNameField = value;
        }
    }

    /// <remarks/>
    public decimal deductionHourlyAmt
    {
        get
        {
            return this.deductionHourlyAmtField;
        }
        set
        {
            this.deductionHourlyAmtField = value;
        }
    }
}

/// <remarks/>
[System.SerializableAttribute()]
[System.ComponentModel.DesignerCategoryAttribute("code")]
[System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
public partial class WaPWCPRPayrollPayrollWeekEmployeesEmployeeTradeHoursWages
{

    private WaPWCPRPayrollPayrollWeekEmployeesEmployeeTradeHoursWagesTradeHoursWage tradeHoursWageField;

    /// <remarks/>
    public WaPWCPRPayrollPayrollWeekEmployeesEmployeeTradeHoursWagesTradeHoursWage tradeHoursWage
    {
        get
        {
            return this.tradeHoursWageField;
        }
        set
        {
            this.tradeHoursWageField = value;
        }
    }
}

/// <remarks/>
[System.SerializableAttribute()]
[System.ComponentModel.DesignerCategoryAttribute("code")]
[System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
public partial class WaPWCPRPayrollPayrollWeekEmployeesEmployeeTradeHoursWagesTradeHoursWage
{

    private string tradeField;

    private string jobClassField;

    private string countyField;

    private decimal regularHourRateAmtField;

    private decimal overtimeHourRateAmtField;

    private decimal doubletimeHourRateAmtField;

    private decimal hourlyPensionRateAmtField;

    private decimal hourlyMedicalAmtField;

    private decimal hourlyVacationAmtField;

    private decimal hourlyHolidayAmtField;

    private decimal apprenticeBenefitAmtField;

    private bool apprenticeFlgField;

    private object apprenticeIdField;

    private object apprenticeStateField;

    private object apprenticeOccpnNameField;

    private object apprenticeStepNameField;

    private object apprenticeStepBeginHoursField;

    private object apprenticeStepEndHoursField;

    private byte regularDay1HoursField;

    private byte regularDay2HoursField;

    private byte regularDay3HoursField;

    private byte regularDay4HoursField;

    private byte regularDay5HoursField;

    private byte regularDay6HoursField;

    private byte regularDay7HoursField;

    private byte overtimeDay1HoursField;

    private byte overtimeDay2HoursField;

    private byte overtimeDay3HoursField;

    private byte overtimeDay4HoursField;

    private byte overtimeDay5HoursField;

    private byte overtimeDay6HoursField;

    private byte overtimeDay7HoursField;

    private byte doubletimeDay1HoursField;

    private byte doubletimeDay2HoursField;

    private byte doubletimeDay3HoursField;

    private byte doubletimeDay4HoursField;

    private byte doubletimeDay5HoursField;

    private byte doubletimeDay6HoursField;

    private byte doubletimeDay7HoursField;

    private WaPWCPRPayrollPayrollWeekEmployeesEmployeeTradeHoursWagesTradeHoursWageTradeBenefits tradeBenefitsField;

    /// <remarks/>
    public string trade
    {
        get
        {
            return this.tradeField;
        }
        set
        {
            this.tradeField = value;
        }
    }

    /// <remarks/>
    public string jobClass
    {
        get
        {
            return this.jobClassField;
        }
        set
        {
            this.jobClassField = value;
        }
    }

    /// <remarks/>
    public string county
    {
        get
        {
            return this.countyField;
        }
        set
        {
            this.countyField = value;
        }
    }

    /// <remarks/>
    public decimal regularHourRateAmt
    {
        get
        {
            return this.regularHourRateAmtField;
        }
        set
        {
            this.regularHourRateAmtField = value;
        }
    }

    /// <remarks/>
    public decimal overtimeHourRateAmt
    {
        get
        {
            return this.overtimeHourRateAmtField;
        }
        set
        {
            this.overtimeHourRateAmtField = value;
        }
    }

    /// <remarks/>
    public decimal doubletimeHourRateAmt
    {
        get
        {
            return this.doubletimeHourRateAmtField;
        }
        set
        {
            this.doubletimeHourRateAmtField = value;
        }
    }

    /// <remarks/>
    public decimal hourlyPensionRateAmt
    {
        get
        {
            return this.hourlyPensionRateAmtField;
        }
        set
        {
            this.hourlyPensionRateAmtField = value;
        }
    }

    /// <remarks/>
    public decimal hourlyMedicalAmt
    {
        get
        {
            return this.hourlyMedicalAmtField;
        }
        set
        {
            this.hourlyMedicalAmtField = value;
        }
    }

    /// <remarks/>
    public decimal hourlyVacationAmt
    {
        get
        {
            return this.hourlyVacationAmtField;
        }
        set
        {
            this.hourlyVacationAmtField = value;
        }
    }

    /// <remarks/>
    public decimal hourlyHolidayAmt
    {
        get
        {
            return this.hourlyHolidayAmtField;
        }
        set
        {
            this.hourlyHolidayAmtField = value;
        }
    }

    /// <remarks/>
    public decimal apprenticeBenefitAmt
    {
        get
        {
            return this.apprenticeBenefitAmtField;
        }
        set
        {
            this.apprenticeBenefitAmtField = value;
        }
    }

    /// <remarks/>
    public bool apprenticeFlg
    {
        get
        {
            return this.apprenticeFlgField;
        }
        set
        {
            this.apprenticeFlgField = value;
        }
    }

    /// <remarks/>
    public object apprenticeId
    {
        get
        {
            return this.apprenticeIdField;
        }
        set
        {
            this.apprenticeIdField = value;
        }
    }

    /// <remarks/>
    public object apprenticeState
    {
        get
        {
            return this.apprenticeStateField;
        }
        set
        {
            this.apprenticeStateField = value;
        }
    }

    /// <remarks/>
    public object apprenticeOccpnName
    {
        get
        {
            return this.apprenticeOccpnNameField;
        }
        set
        {
            this.apprenticeOccpnNameField = value;
        }
    }

    /// <remarks/>
    public object apprenticeStepName
    {
        get
        {
            return this.apprenticeStepNameField;
        }
        set
        {
            this.apprenticeStepNameField = value;
        }
    }

    /// <remarks/>
    public object apprenticeStepBeginHours
    {
        get
        {
            return this.apprenticeStepBeginHoursField;
        }
        set
        {
            this.apprenticeStepBeginHoursField = value;
        }
    }

    /// <remarks/>
    public object apprenticeStepEndHours
    {
        get
        {
            return this.apprenticeStepEndHoursField;
        }
        set
        {
            this.apprenticeStepEndHoursField = value;
        }
    }

    /// <remarks/>
    public byte regularDay1Hours
    {
        get
        {
            return this.regularDay1HoursField;
        }
        set
        {
            this.regularDay1HoursField = value;
        }
    }

    /// <remarks/>
    public byte regularDay2Hours
    {
        get
        {
            return this.regularDay2HoursField;
        }
        set
        {
            this.regularDay2HoursField = value;
        }
    }

    /// <remarks/>
    public byte regularDay3Hours
    {
        get
        {
            return this.regularDay3HoursField;
        }
        set
        {
            this.regularDay3HoursField = value;
        }
    }

    /// <remarks/>
    public byte regularDay4Hours
    {
        get
        {
            return this.regularDay4HoursField;
        }
        set
        {
            this.regularDay4HoursField = value;
        }
    }

    /// <remarks/>
    public byte regularDay5Hours
    {
        get
        {
            return this.regularDay5HoursField;
        }
        set
        {
            this.regularDay5HoursField = value;
        }
    }

    /// <remarks/>
    public byte regularDay6Hours
    {
        get
        {
            return this.regularDay6HoursField;
        }
        set
        {
            this.regularDay6HoursField = value;
        }
    }

    /// <remarks/>
    public byte regularDay7Hours
    {
        get
        {
            return this.regularDay7HoursField;
        }
        set
        {
            this.regularDay7HoursField = value;
        }
    }

    /// <remarks/>
    public byte overtimeDay1Hours
    {
        get
        {
            return this.overtimeDay1HoursField;
        }
        set
        {
            this.overtimeDay1HoursField = value;
        }
    }

    /// <remarks/>
    public byte overtimeDay2Hours
    {
        get
        {
            return this.overtimeDay2HoursField;
        }
        set
        {
            this.overtimeDay2HoursField = value;
        }
    }

    /// <remarks/>
    public byte overtimeDay3Hours
    {
        get
        {
            return this.overtimeDay3HoursField;
        }
        set
        {
            this.overtimeDay3HoursField = value;
        }
    }

    /// <remarks/>
    public byte overtimeDay4Hours
    {
        get
        {
            return this.overtimeDay4HoursField;
        }
        set
        {
            this.overtimeDay4HoursField = value;
        }
    }

    /// <remarks/>
    public byte overtimeDay5Hours
    {
        get
        {
            return this.overtimeDay5HoursField;
        }
        set
        {
            this.overtimeDay5HoursField = value;
        }
    }

    /// <remarks/>
    public byte overtimeDay6Hours
    {
        get
        {
            return this.overtimeDay6HoursField;
        }
        set
        {
            this.overtimeDay6HoursField = value;
        }
    }

    /// <remarks/>
    public byte overtimeDay7Hours
    {
        get
        {
            return this.overtimeDay7HoursField;
        }
        set
        {
            this.overtimeDay7HoursField = value;
        }
    }

    /// <remarks/>
    public byte doubletimeDay1Hours
    {
        get
        {
            return this.doubletimeDay1HoursField;
        }
        set
        {
            this.doubletimeDay1HoursField = value;
        }
    }

    /// <remarks/>
    public byte doubletimeDay2Hours
    {
        get
        {
            return this.doubletimeDay2HoursField;
        }
        set
        {
            this.doubletimeDay2HoursField = value;
        }
    }

    /// <remarks/>
    public byte doubletimeDay3Hours
    {
        get
        {
            return this.doubletimeDay3HoursField;
        }
        set
        {
            this.doubletimeDay3HoursField = value;
        }
    }

    /// <remarks/>
    public byte doubletimeDay4Hours
    {
        get
        {
            return this.doubletimeDay4HoursField;
        }
        set
        {
            this.doubletimeDay4HoursField = value;
        }
    }

    /// <remarks/>
    public byte doubletimeDay5Hours
    {
        get
        {
            return this.doubletimeDay5HoursField;
        }
        set
        {
            this.doubletimeDay5HoursField = value;
        }
    }

    /// <remarks/>
    public byte doubletimeDay6Hours
    {
        get
        {
            return this.doubletimeDay6HoursField;
        }
        set
        {
            this.doubletimeDay6HoursField = value;
        }
    }

    /// <remarks/>
    public byte doubletimeDay7Hours
    {
        get
        {
            return this.doubletimeDay7HoursField;
        }
        set
        {
            this.doubletimeDay7HoursField = value;
        }
    }

    /// <remarks/>
    public WaPWCPRPayrollPayrollWeekEmployeesEmployeeTradeHoursWagesTradeHoursWageTradeBenefits tradeBenefits
    {
        get
        {
            return this.tradeBenefitsField;
        }
        set
        {
            this.tradeBenefitsField = value;
        }
    }
}

/// <remarks/>
[System.SerializableAttribute()]
[System.ComponentModel.DesignerCategoryAttribute("code")]
[System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
public partial class WaPWCPRPayrollPayrollWeekEmployeesEmployeeTradeHoursWagesTradeHoursWageTradeBenefits
{

    private WaPWCPRPayrollPayrollWeekEmployeesEmployeeTradeHoursWagesTradeHoursWageTradeBenefitsTradeBenefit tradeBenefitField;

    /// <remarks/>
    public WaPWCPRPayrollPayrollWeekEmployeesEmployeeTradeHoursWagesTradeHoursWageTradeBenefitsTradeBenefit tradeBenefit
    {
        get
        {
            return this.tradeBenefitField;
        }
        set
        {
            this.tradeBenefitField = value;
        }
    }
}

/// <remarks/>
[System.SerializableAttribute()]
[System.ComponentModel.DesignerCategoryAttribute("code")]
[System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
public partial class WaPWCPRPayrollPayrollWeekEmployeesEmployeeTradeHoursWagesTradeHoursWageTradeBenefitsTradeBenefit
{

    private string benefitHourlyNameField;

    private decimal benefitHourlyAmtField;

    /// <remarks/>
    public string benefitHourlyName
    {
        get
        {
            return this.benefitHourlyNameField;
        }
        set
        {
            this.benefitHourlyNameField = value;
        }
    }

    /// <remarks/>
    public decimal benefitHourlyAmt
    {
        get
        {
            return this.benefitHourlyAmtField;
        }
        set
        {
            this.benefitHourlyAmtField = value;
        }
    }
}



namespace SpecialPasteXML
{
    class XMLPaste
    {
    }
}
