#pragma once

#include <string>
#include <vector>
#include <algorithm>

// Minimal Roblox-shaped scene object. Extend this in your own engine to back
// it with real transforms, render state, physics bodies, etc. This base class
// only tracks the console-visible shape: Name/ClassName/Parent/Children.
class Instance {
public:
    Instance(std::string className, std::string name)
        : ClassName(std::move(className)), Name(std::move(name)) {}

    virtual ~Instance() {
        SetParent(nullptr);
        // Orphan children rather than recursively deleting; ownership of
        // child lifetime belongs to your engine, not this console layer.
        for (Instance* child : Children) {
            child->parent_ = nullptr;
        }
    }

    const std::string ClassName;
    std::string Name;

    Instance* GetParent() const { return parent_; }

    void SetParent(Instance* newParent) {
        if (parent_ == newParent) return;
        if (parent_) {
            auto& siblings = parent_->Children;
            siblings.erase(std::remove(siblings.begin(), siblings.end(), this), siblings.end());
        }
        parent_ = newParent;
        if (parent_) {
            parent_->Children.push_back(this);
        }
    }

    const std::vector<Instance*>& GetChildren() const { return Children; }

    Instance* FindFirstChild(const std::string& name) const {
        for (Instance* child : Children) {
            if (child->Name == name) return child;
        }
        return nullptr;
    }

    virtual void Destroy() {
        if (destroyed_) return;
        destroyed_ = true;
        SetParent(nullptr);
    }

    bool IsDestroyed() const { return destroyed_; }

private:
    Instance* parent_ = nullptr;
    std::vector<Instance*> Children;
    bool destroyed_ = false;
};
