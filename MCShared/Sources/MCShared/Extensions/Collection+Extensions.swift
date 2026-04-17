public extension Collection {

    /// Acessa um elemento pelo índice sem risco de crash.
    /// Retorna `nil` se o índice estiver fora dos limites da coleção.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
