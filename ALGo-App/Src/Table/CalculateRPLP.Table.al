table 50101 "CalculateRPLP"
{
    DataClassification = SystemMetadata;
    AllowInCustomizations = Never;

    fields
    {
        field(1; Code; Integer)
        {
        }
        field(2; "Total RPLP Line Amount"; Decimal)
        {

        }
    }

    keys
    {
        key(Key1; Code)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    trigger OnInsert()
    begin

    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

}