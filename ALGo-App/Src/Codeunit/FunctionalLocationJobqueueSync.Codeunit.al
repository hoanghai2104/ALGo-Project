codeunit 50111 FunctionalLocationJobqueueSync
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        JobQueue();
    end;


    procedure JobQueue()
    var
        jobQueueEntry: Record "Job Queue Entry";
        integationMapping: Record "Integration Table Mapping";

    begin
        integationMapping.get('SHIP TO ADDRESS');

        jobQueueEntry.Reset();
        jobQueueEntry.SetRange("Record ID to Process", integationMapping.RecordId);
        if jobQueueEntry.FindFirst() then
            exit;
        jobQueueEntry.Init();
        jobQueueEntry."Object Type to Run" := jobQueueEntry."Object Type to Run"::Codeunit;
        jobQueueEntry."Object ID to Run" := 5339;
        jobQueueEntry.Validate("Object ID to Run");
        jobQueueEntry.Description := 'Sync Functional Location <> Ship to Address';
        jobQueueEntry."Parameter String" := '222';
        jobQueueEntry."Record ID to Process" := integationMapping.RecordId;
        jobQueueEntry.Insert(true);

    end;
    //in
}