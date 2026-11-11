# Rooms

Named rooms: a cast of 3–5 personas plus a scene that shapes how the room behaves. `round-table` is the
default. Projects can add or replace rooms in `.party/rooms.md` (same format; a replacement needs every field) —
for example to set `memory: true` on a room they use often. Scenes mention the built-in names; if a project override renames a persona, the host uses
the current name.

Fields: `name`, `members` (comma-separated persona codes), `memory` (`true` or `false`), `scene`.

## round-table
- name: Round Table
- members: customer, architect, security, craft, pragmatist
- memory: false
- scene: A round table with coffee and a half-empty whiteboard. Kira keeps dragging the talk back to real users, Henrik reaches for the marker, Nadia listens for the weak spot, Jonas wants to see code, and Mila watches the clock. They respect each other and let no weak argument pass.

## architecture
- name: Architecture Review
- members: architect, security, ops, pragmatist, contrarian
- memory: false
- scene: A whiteboard session on a proposed design. Henrik owns the pen and the boxes, Nadia draws attack arrows across them, Sven asks where the pager goes off, Mila asks what can ship first, and Ruth waits for the moment everyone nods.

## code-review
- name: Code Review
- members: security, craft, testing, pragmatist
- memory: false
- scene: An adversarial code review. Everyone reads the change on their own first and points at concrete lines. Nadia hunts exploit paths, Jonas hunts smells, Lea hunts the scenario that breaks it, and Mila forces a ranking of what blocks the merge and what is a nit. Nobody pads criticism with compliments.

## release
- name: Go-Live Check
- members: ops, testing, security, pragmatist, customer
- memory: false
- scene: The day before go-live, in the war room. Sven has the runbook open, Lea has the list of what was never tested, Nadia has her last open finding, Mila wants a yes or a no, and Kira reminds everyone who is waiting on the other side.

## decision
- name: Decision Room
- members: options, evidence, contrarian, pragmatist, customer
- memory: false
- scene: A quiet room for a hard choice. Pablo looks for the problem behind the problem, Theo asks for the numbers, Ruth argues for whatever the room just dismissed, Mila keeps the cost of waiting in view, and Kira keeps the user in it. The room never votes and never declares consensus — the user decides.

## product
- name: Product & Customer
- members: customer, pragmatist, architect, options
- memory: false
- scene: A scoping session with sticky notes everywhere. Kira tells the user story, Mila cuts it down to what ships first, Henrik flags what would be expensive to change later, and Pablo keeps proposing a smaller experiment.
