codeunit 50113 ReportFormatHelper
{
    Access = Internal;

    procedure DecimalWordFormat(Amount: Decimal): Text
    var
        FormatedAmount: Text;
    begin
        if Amount = 0 then
            FormatedAmount := ''
        else
            FormatedAmount := StrSubstNo('%1%', Amount);
        exit(FormatedAmount);
    end;

}