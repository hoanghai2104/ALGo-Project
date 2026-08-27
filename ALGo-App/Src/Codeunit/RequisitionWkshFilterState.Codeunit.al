codeunit 50174 "Requisition Wksh. Filter State"
{
    SingleInstance = true;

    var
        ToOrderFilterState: Enum "Requisition Wksh. To Order";

    procedure SetToOrderMode(NewToOrderFilter: Enum "Requisition Wksh. To Order")
    begin
        ToOrderFilterState := NewToOrderFilter;
    end;

    procedure GetToOrderMode(): Enum "Requisition Wksh. To Order";
    begin
        exit(ToOrderFilterState);
    end;

    procedure Dispose()
    begin
        Clear(ToOrderFilterState);
    end;
}