(local state (require :polywell.state))
(local utf8 (require :polywell.lib.utf8))
(local lume (require :polywell.lib.lume))

(fn find-common [a b so-far]
  (if (or (= 0 (# a))
          (not= (utf8.sub a 1 1) (utf8.sub b 1 1)))
      (or so-far "")
      (find-common (utf8.sub a 2)
                   (utf8.sub b 2)
                   (.. (or so-far "") (utf8.sub a 1 1)))))

(fn longest-common-prefix [strings common i]
  (let [common (or common (. strings 1) "") i (or i 2)
        new-common (find-common common (. strings i))]
    (if (= i (# strings))
        new-common
        (or (not new-common) (= common ""))
        ""
        (longest-common-prefix strings new-common (+ i 1)))))

(fn match? [target input fuzzy?]
  (if fuzzy?
      (string.find target input)
      (= (utf8.sub target 1 (# input)) input)))

(fn add-matches [matches input keys fuzzy?]
  (each [_ v (ipairs keys)]
    (when (and (= (type v) "string") (match? v input fuzzy?))
      (table.insert matches v)))
  ;; if there's an exact match, it should go first
  (let [i (lume.find matches input)]
    (when i (table.insert matches 1 (table.remove matches i))))
  (when (and (= 0 (# matches)) (not fuzzy?))
    (add-matches matches input keys true)))

(fn add-prefixes [t input prefixes]
  (let [parts (lume.split input ".")]
    (if (and (< 1 (# parts)) (= (type t) :table))
        (let [first (table.remove parts 1)]
          (when (. t first)
            (table.insert prefixes first)
            (add-prefixes (. t first) (table.concat parts ".") prefixes)))
        (let [prefixed []]
          (each [entry (pairs t)]
            (table.insert prefixes entry)
            (table.insert prefixed (table.concat prefixes "."))
            (table.remove prefixes))
          prefixed))))

(fn completions-for [context input]
  (if (= (type context) "table")
      (let [keys (lume.keys context)
            context (if (and (= (# context) 0) (> (# keys) 0))
                        keys context)]
        ;; if we have an array, use as-is
        ;; for a k/v table or proxied table, use keys
        (doto {} (add-matches input context false)))
      {}))

{:longest-common-prefix longest-common-prefix
 :add-prefixes add-prefixes
 :for completions-for}
