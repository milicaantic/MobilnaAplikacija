/// Status of an event in the approval workflow.
///
/// - [pending]: Newly created, awaiting admin approval.
/// - [approved]: Approved by an admin, visible to all users.
/// - [rejected]: Rejected by an admin with a reason.
enum EventStatus { pending, approved, rejected }
