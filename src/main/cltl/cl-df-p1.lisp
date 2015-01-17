;; cl-df-p1.lisp - a simple data flow programming prototype

#|

Primary reference:
[J2004] Johnston, Wesley JR, Paul Hanna ans Richard Millar. Advances in Dataflow Programming Languages. ACM Comput. Surv. 2004.

|#

(in-package #:cl-user)

(eval-when (:compile-toplevel :load-toplevel :execute)
        (defpackage #:df.p1
                (:use #:cl))
)

(in-package #:df.p1)

(defclass data-source ()
        ())

(defclass data-sink ()
        ())

(defclass constant (data-source)
        ())

(defgeneric data-available-p (source)
        (:method ((source constant))
                (values t nl)))


(defclass op ()
        ()) ;; op impl. may be either or both of data source/sink

(defgeneric run-op (op)) ;; oversimplified?


(defclass pin (data-source data-sink)
        ())


(defclass op-type ()
        ())

(defclass monadic-op-type (op-type)
        ;; op-type for operation providing a single "output pin"
        ())

(defclass mv-op-type (op-type)
        ;; op-type for operations providing multiple "ouput pins"
        ())

(degeneric op-type-input-pins (type))
;; => list of pin

(defgenric op-type-output-pins (type))
;; => list of pin


(defclass wire ()
        ((input-pin
                :initarg :input-pin
                :accessor wire-input-pin
                :type pin)
        (output-pin
                :initarg :input-pin
                :accessor wire-output-pin
                :type pin)))

(defgeneric op-inputs (op))
;; => sequence of wire

(defgeneic op-outputs (op))
;; => sequence of wire


(defclass op-class (standard-class op-type)
        ())

(defclass monadic-op-class (op-class monadic-op-type)
        ())

(defclass mv-op-class (op-class mv-op-type)
        ())


(defclass functional-op-type (op-type)
        ;; FIXME: In SHARED-INITIALIZE :AROUND (?)
        ;; ensure NATIVE-FUNCTION is compiled (when possible??)
        ((native-function
                :initarg :native-fuction
                :type function
                :accessor op-type-nayive-function))

(defclass functional-op-class (op-class functional-op-type)
        ())

(defclass monadic-functional-op-class (monadic-op-class functional-op-class)
        ())

(defclass mv-functional-op-class (mv-op-class functional-op-class)
        ())

(deflass add-op (op data-source data-sink)
        ()
        (:metaclass functional-monadic-op-class))

(defmethod run-op ((op add-op))
;; referencing [J2004], two approaches for implementing a dataflow model:
;;
;; 1. data-driven approach
;;    * essentially towards a "top-down" control flow in implementing a data flow graph.
;;
;; 2. demand-driven approach
;;    * essentially towards a "bottom-up" control flow.
;;
;; Ostensibly, both approaches may be implemented – towards developing an interactive, functional data flow implementation in Commom Lisp.
;;
;; Use case: Data Flow Program , P, "Simple adder"
;;
;; Given:
;;   Node A0, providing constant value "1" on single outout pin A0P0
;;   Node A1, providing constant value "2" on single output pin A1P0
;;   Node B0, "Addition operation", two input pins (B0R0, B0R1), single output pin (B0P0)
;;   Node C0, "Value predentation", one input pin (C0R0), no output pins
;;   Wiring:
;;     (A0P0, B0R0)
;;     (A1P0, B0R1)
;;     (B0P0, C0R0)
;;
;; Scenario 1: P evaluated in data-driven evaluation
;;
;;     Use case scenario: User requests P evluation
;;
;;    Procedural overview:
;;
;;   1. Starting at initial "top" nodes A0, A1, ensure data is available to be read from "print" pins of each node (i.e A0P0, A1P0). Whereas this scenario implements A0, A1 as "Constant value" nodes (contrast: meaurement sampling nodes) data will be constantly available on A0P0, A1P0
;;
;;   2. Availability of data on A0P0, A1P0 => "Evaluate wiring" => Evaluate B0
;;
;;      Procedure (abstract) :
;;
;;		1. Access "wire configuration" for A0, A1 output pins
;;			* Data is available on A0P0 => Data is available on B0R0 (activate pin B0R0 on node B0, check if all B0 "read" pins are active, evaluate B0 if so)
;;
;;			* Data is available on A1P0 => Data is available on B0R1 (activate pin B0R1 on node B0, check if all B0 "read" pins are active, and now that is "true", evaluate B0 )
;;
;;      2. On activation of all "read"" pins on B0, evaluate B0 (functional evaluation).
;;
;;      3. On completion of functional evaluation of B0, store values in  B0 "print" pins (B0P0), and activate each "print" pin. After thr resulting data values are stored onto each/all (?) "print" pins, then "cascade the activation signal" onto those "print" pins.

;; (NOTE: CONFIGURATION AND HOST SUPPORT: PARALLEL i.e "multithreaded" (i.e available only in multi-threaded host environments) or SERIAL i.e "single-threaded" (i.e available in every host envirpnment) NODE ACTIVATION CASCADE i.e node signal/evaluation methodlogy - USER-ACCESSIBLE CONFIGURATION OPTION, CONFIGURABLE PER: EACH APPLICATION, EACH PROGRAM, AND EACH NODE. FURTHER CONFIGURATION (PER NODE): NODAL CASCADE SEQUENCE (FOR SERIAL CASCADE))
;;
;;          1. "Evaluate wires" on pin B0P0
;;                B0P0 ... C0R0
;;          2. Store data value onto C0R0 (node C0) and activate C0R0
;;          3. Evaluate Node C0 (functional evaluation)
;;
;.      4. Node C0 presents its input data value (e.g using synthesized speech as in an audible event notification model, and/or presenting the data value onto a graphical display screen as in a digital graphical event notification model, or displaying the value onto a single, digital LED readout on a microcontroller, in a modular microcontroller design, and optionally presenting the value for storage in an event-series data logging model, for use in system metrics and reporting. Inspired by U. Edinburgh CSTR's Festival Speech Synthesis System, digital multimeter models with data logging capability, oscilloscope with data logging capability, Arduino, Adafruit, NI PXI, Idaho National Laboratory (social networking), Jasper Reports, and Franchise Tax Board)
;;
;;
;; Scenario 2: P evaluated in demand-driven "sample mode" evaluation beginning at C0
;;
;;     Use case scenario: User requests sample of current data value at C0
;;
;;    Procedural overview:
;;
;;        Starting at node C0:
;;     1. Retrieve list of "read" pins on C0
;;         => C0R0
;;     2. Determine the "wire" for each "read" pin, then the respective "peer pin" of wire, then the node containing that "peer pin"
;,        B0P0 => (B0P0, C0R0) => C0R0 => C0
;;     3. Determine "node availability" (node C0), i.e Determine, Is Data availabile on all "read" pins in C0? (i.e for each "read" pin on C0, compute "read" pin => wire => print pin => node => availability) until arriving at a set of "available" nodes having no "read" pins.
;;     4. Given set of "initial top nodes", then begin top-down functional evaluation, starting with that set of "initial top nodes" (optionally, towards a "Debug mode" requirement: isolate evaluation to the "call tree" -- i.e data flow graph -- as computed in this instance, as beginning at C0, essentially "disabling" any "print pins" not included in that data flow graph. The "Isolated Debug" call tree for C0, as an object, may be assigned to C0, once computed.)
;;
        (to-do ))

(define-condition to-do (program-error)
        ((annotations :initarg :annotations :reader condition-annotations :initform nil))
        (:report (lambda (c s) (format s "To Do~@[~s~]" (condition-annotations c)))))

(defmacro to-do (&rest annotations)
        `(evaluate-when (:compile-toplevel)
                 (error 'to-do :annotations (list ,@annotations))))
