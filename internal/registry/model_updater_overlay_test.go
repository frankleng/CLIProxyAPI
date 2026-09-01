package registry

import "testing"

func TestApplyEmbeddedModelOverlaysAddsFable51(t *testing.T) {
	remote := &staticModelsJSON{
		Claude: []*ModelInfo{{ID: "claude-fable-5", DisplayName: "Claude Fable 5"}},
	}

	applyEmbeddedModelOverlays(remote)

	var found *ModelInfo
	for _, model := range remote.Claude {
		if model != nil && model.ID == "claude-fable-5-1" {
			found = model
			break
		}
	}
	if found == nil {
		t.Fatal("claude-fable-5-1 overlay was not added")
	}
	if found.Thinking == nil || found.Thinking.ZeroAllowed || !found.Thinking.DynamicAllowed {
		t.Fatalf("unexpected Fable 5.1 thinking metadata: %#v", found.Thinking)
	}
}

func TestApplyEmbeddedModelOverlaysPreservesRemoteFable51(t *testing.T) {
	remoteModel := &ModelInfo{ID: "claude-fable-5-1", DisplayName: "Remote Fable 5.1"}
	remote := &staticModelsJSON{Claude: []*ModelInfo{remoteModel}}

	applyEmbeddedModelOverlays(remote)

	if len(remote.Claude) != 1 {
		t.Fatalf("expected one Fable 5.1 entry, got %d", len(remote.Claude))
	}
	if remote.Claude[0] != remoteModel {
		t.Fatal("remote Fable 5.1 metadata was replaced by the embedded overlay")
	}
}
