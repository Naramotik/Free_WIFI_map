package com.example.demo.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Entity
@Data
@AllArgsConstructor
@NoArgsConstructor
@Table(name = "client")
public class Client {
    @Id
    @Column(name = "id")
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    Long id;
    @Column(name = "email")
    String email;
    @Column(name = "displayname")
    String displayName;

    @JsonIgnore
    @OneToMany(mappedBy = "client")
    private List<Comment> comments;

    @JsonIgnore
    @OneToMany(mappedBy = "client")
    private List<Grade> grades;

    @Column(name = "role")
    String role;

    @JsonIgnore
    @OneToMany(mappedBy = "client")
    private List<Complain> complains;

    @JsonIgnore
    @OneToMany(mappedBy = "client")
    private List<Mark> marks;
}
