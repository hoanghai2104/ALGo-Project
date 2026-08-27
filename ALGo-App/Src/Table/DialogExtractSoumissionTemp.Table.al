table 50104 DialogExtractSoumissionTemp
{
    DataClassification = ToBeClassified;
    AllowInCustomizations = Never;
    // TableType = Temporary;
    fields
    {
        field(1; customerID; Code[20])
        {
            TableRelation = Customer."No.";
            NotBlank = true;
        }
        field(2; PK; Integer)
        {
            AutoIncrement = true;
        }
        field(3; "DevisID"; Code[20])
        {

        }
    }

}