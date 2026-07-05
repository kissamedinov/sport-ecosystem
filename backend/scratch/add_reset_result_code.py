import os

def main():
    # 1. Update match_repository.dart
    repo_path = 'lib/features/matches/data/repositories/match_repository.dart'
    if os.path.exists(repo_path):
        with open(repo_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        target = """  Future<void> finalizeResult(String matchId, Map<String, dynamic> resultData) async {
    await _apiClient.patch('/matches/$matchId/finalize-result', data: resultData);
  }"""
        replacement = """  Future<void> finalizeResult(String matchId, Map<String, dynamic> resultData) async {
    await _apiClient.patch('/matches/$matchId/finalize-result', data: resultData);
  }

  Future<void> resetResult(String matchId) async {
    await _apiClient.post('/matches/$matchId/reset-result');
  }"""
        if target in content and "resetResult" not in content:
            content = content.replace(target, replacement)
            with open(repo_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print("match_repository.dart updated!")
            
    # 2. Update match_provider.dart
    prov_path = 'lib/features/matches/providers/match_provider.dart'
    if os.path.exists(prov_path):
        with open(prov_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        target = """  Future<void> submitResult(String matchId, Map<String, dynamic> resultData) async {
    _setLoading(true);
    try {
      await _repository.submitResult(matchId, resultData);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }"""
        replacement = """  Future<void> submitResult(String matchId, Map<String, dynamic> resultData) async {
    _setLoading(true);
    try {
      await _repository.submitResult(matchId, resultData);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetResult(String matchId) async {
    _setLoading(true);
    try {
      await _repository.resetResult(matchId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }"""
        if target in content and "resetResult" not in content:
            content = content.replace(target, replacement)
            with open(prov_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print("match_provider.dart updated!")

if __name__ == '__main__':
    main()
